#!/bin/bash
set -e

ENTITY_FILE="entities.xml"
XSLT_FILE="/jira-markdown/page_to_html.xsl"
OUT_DIR="wiki_output"
TMP_DIR="tmp_xml"

mkdir -p "$OUT_DIR" "$TMP_DIR"

echo "📄 Parsing entities.xml..."

# Step 1: Extract PageID|Title|ParentID into page_tree.txt
PAGE_TREE="page_tree.txt"

xmlstarlet sel -t \
  -m "//object[@class='Page']" \
  -v "concat(id[@name='id'], '|', property[@name='title'], '|', property[@name='parent']/id[@name='id'])" \
  -n "$ENTITY_FILE" > "$PAGE_TREE"

echo "✅ Extracted page list: $(wc -l < $PAGE_TREE) pages"

# Step 2: Build associative arrays: title and parent
declare -A TITLE_MAP PARENT_MAP SLUG_MAP

while IFS='|' read -r ID TITLE PARENT; do
  [[ -z "$ID" ]] && continue
  TITLE_MAP["$ID"]="$TITLE"
  PARENT_MAP["$ID"]="$PARENT"

  # Generate slug: safe filename
  SLUG=$(echo "$TITLE" | tr ' /\\:*?"<>|' '_' | tr -cd '[:alnum:]_-')
  [[ -z "$SLUG" ]] && SLUG="page_$ID"
  SLUG_MAP["$ID"]="$SLUG"
done < "$PAGE_TREE"

# Step 3: Recursively build path from page to root
declare -A PATH_MAP

build_path() {
  local ID="$1"
  local PARENT="${PARENT_MAP[$ID]}"
  local SLUG="${SLUG_MAP[$ID]}"
  local PATH=""

  if [[ -n "$PARENT" && -n "${SLUG_MAP[$PARENT]}" ]]; then
    PATH="$(build_path "$PARENT")/$SLUG"
  else
    PATH="$SLUG"
  fi

  PATH_MAP["$ID"]="$PATH"
  echo "$PATH"
}

echo "📁 Building folder structure and converting pages..."

# Step 4: Process each page
COUNT=0
for ID in "${!TITLE_MAP[@]}"; do
  TITLE="${TITLE_MAP[$ID]}"
  SLUG="${SLUG_MAP[$ID]}"
  PAGE_PATH=$(build_path "$ID")
  OUT_PATH="$OUT_DIR/$PAGE_PATH"
  mkdir -p "$OUT_PATH"

  # Build temp XML for this page
  TEMP_XML="$TMP_DIR/$ID.xml"
  set +e
  {
    echo '<?xml version="1.0"?><root>'
    xmlstarlet sel -t -c "//object[@class='Page'][id[@name='id']=concat('', '$ID', '')]" "$ENTITY_FILE"
    xmlstarlet sel -t -c "//object[@class='BodyContent'][property[@name='content']/id[@name='id']=concat('', '$ID', '')]" "$ENTITY_FILE"
    echo '</root>'
  } > "$TEMP_XML"
  set -e

  # Skip if empty
  if [[ ! -s "$TEMP_XML" ]]; then
    echo "⚠️ Skipping $TITLE (no content)"
    continue
  fi

  # Convert to HTML
  xsltproc "$XSLT_FILE" "$TEMP_XML" > "$OUT_PATH/index.html"
  echo "✅ $TITLE → $OUT_PATH/index.html"
  COUNT=$((COUNT + 1))
done

# Step 5: Generate global index.html
echo "🌐 Building TOC..."

INDEX_HTML="$OUT_DIR/index.html"
echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Wiki Index</title></head><body>" > "$INDEX_HTML"
echo "<h1>Wiki Pages</h1><ul>" >> "$INDEX_HTML"

# Recursively write tree
print_tree() {
  local PARENT_ID="$1"
  for ID in "${!TITLE_MAP[@]}"; do
    if [[ "${PARENT_MAP[$ID]}" == "$PARENT_ID" ]]; then
      local TITLE="${TITLE_MAP[$ID]}"
      local LINK="${PATH_MAP[$ID]}/index.html"
      echo "<li><a href=\"$LINK\">$TITLE</a></li>" >> "$INDEX_HTML"
      echo "<ul>" >> "$INDEX_HTML"
      print_tree "$ID"
      echo "</ul>" >> "$INDEX_HTML"
    fi
  done
}

print_tree ""
echo "</ul></body></html>" >> "$INDEX_HTML"

echo "✅ Wiki HTML built: $COUNT pages"
echo "📂 Output directory: $OUT_DIR"
echo "🌐 View root: $OUT_DIR/index.html"
