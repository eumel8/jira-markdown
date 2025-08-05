#!/bin/bash

set -e

INPUT_ZIP="$1"
[ -z "$INPUT_ZIP" ] && { echo "Usage: $0 export.zip"; exit 1; }
[ ! -f "$INPUT_ZIP" ] && { echo "❌ File not found: $INPUT_ZIP"; exit 1; }

WORK_DIR="./confluence_tmp"
OUTPUT_DIR="./markdown_output"
TMP_DIR="$OUTPUT_DIR/tmp"
MD_DIR="$OUTPUT_DIR/md"
XSLT_FILE="/jira-markdown/page2md.xsl"

# Prepare workspace
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$TMP_DIR" "$MD_DIR"

echo "📦 Unzipping $INPUT_ZIP..."
unzip -o "$INPUT_ZIP" -d "$WORK_DIR" >/dev/null

ENTITY_FILE="$WORK_DIR/entities.xml"
[ ! -f "$ENTITY_FILE" ] && { echo "❌ entities.xml not found in ZIP."; exit 1; }

# Step 1: Extract Page metadata
echo "🔍 Indexing pages..."
xmlstarlet sel -t -m '//object[@class="Page"]' \
  -o "ID=" -v "id[@name='id']" \
  -o ";TITLE=" -v "property[@name='title']" \
  -o ";STATUS=" -v "property[@name='contentStatus']" -n \
  "$ENTITY_FILE" > "$OUTPUT_DIR/page_index.txt"

TOTAL_PAGES=$(wc -l < "$OUTPUT_DIR/page_index.txt")
echo "📄 Total pages found: $TOTAL_PAGES"

# Step 2: Process each Page
i=0
while IFS=';' read -r id_line title_line status_line; do
    # Skip empty or malformed lines
  [[ -z "$id_line" || -z "$title_line" || -z "$status_line" ]] && {
    echo "⚠️ Skipping malformed line: $id_line | $title_line | $status_line"
    continue
  }
  i=$((i + 1))
  echo "immer noch 2"
  echo "✅ [$i] ID=$id_line TITLE=$title_line STATUS=$status_line"
  echo "DEBUG [$i/$TOTAL_PAGES] ID_LINE='$id_line' TITLE_LINE='$title_line' STATUS_LINE='$status_line'"

  PAGE_ID="${id_line#ID=}"
  PAGE_TITLE="${title_line#TITLE=}"
  SAFE_TITLE=$(echo "${PAGE_TITLE:-Untitled_$PAGE_ID}" | tr ' /:' '_' | tr -cd '[:alnum:]_-')
  TEMP_XML="$TMP_DIR/$SAFE_TITLE.xml"
  MD_FILE="$MD_DIR/$SAFE_TITLE.md"

  set +e
  {
    echo '<?xml version="1.0"?><root>'
    xmlstarlet sel -t -c "//object[@class='Page'][id[@name='id']='$PAGE_ID']" "$ENTITY_FILE"
    xmlstarlet sel -t -c "//object[@class='BodyContent'][property[@name='content']/id[@name='id']='$PAGE_ID']" "$ENTITY_FILE"
    echo '</root>'
  } > "$TEMP_XML"
  set -e

  echo "DEBUG TEMP_XML byte‑size=$(wc -c < "$TEMP_XML")"

  if [[ $(wc -c < "$TEMP_XML") -gt 100 ]]; then
    xsltproc "$XSLT_FILE" "$TEMP_XML" | pandoc -f html -t markdown -o "$MD_FILE"
    echo "✓ Wrote '$MD_FILE'"
  else
    echo "⚠️ Skipping empty or tiny XML for $SAFE_TITLE (size=$(wc -c < "$TEMP_XML"))"
  fi

done < "$OUTPUT_DIR/page_index.txt"


echo "✅ All done. Markdown files saved in: $MD_DIR"
