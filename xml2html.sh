#!/bin/bash

ENTITY_FILE="confluence_tmp/entities.xml"
OUT_DIR="html_output"
mkdir -p "$OUT_DIR"

# Index all Page IDs and Titles
xmlstarlet sel -t \
  -m "//object[@class='Page']" \
  -v "concat(id[@name='id'], '|', property[@name='title'])" -n \
  "$ENTITY_FILE" > page_list.txt

echo "📄 Total pages found: $(wc -l < page_list.txt)"

i=0
while IFS='|' read -r PAGE_ID PAGE_TITLE; do
  [[ -z "$PAGE_ID" || -z "$PAGE_TITLE" ]] && continue
  i=$((i + 1))

  SAFE_TITLE=$(echo "$PAGE_TITLE" | tr '/\:*?"<>|' '_' | tr ' ' '_')
  TEMP_XML="./tmp_page.xml"
  OUT_HTML="$OUT_DIR/$SAFE_TITLE.html"

  set +e
  {
    echo '<?xml version="1.0"?><root>'
    xmlstarlet sel -t -c "//object[@class='Page'][id[@name='id']='$PAGE_ID']" "$ENTITY_FILE"
    xmlstarlet sel -t -c "//object[@class='BodyContent'][property[@name='content']/id[@name='id']='$PAGE_ID']" "$ENTITY_FILE"
    echo '</root>'
  } > "$TEMP_XML"
  set -e

  if [[ -s "$TEMP_XML" ]]; then
    xsltproc /jira-markdown/page_to_html.xsl "$TEMP_XML" > "$OUT_HTML"
    echo "✅ [$i] Wrote: $OUT_HTML"
  else
    echo "⚠️ [$i] Skipped: $SAFE_TITLE (empty XML)"
  fi

done < page_list.txt

# Build index
echo "<html><head><meta charset='utf-8'><title>Wiki Index</title></head><body><h1>Wiki Pages</h1><ul>" > "$OUT_DIR/index.html"
for f in "$OUT_DIR"/*.html; do
  name=$(basename "$f")
  [[ "$name" == "index.html" ]] && continue
  echo "<li><a href=\"$name\">${name%.html}</a></li>" >> "$OUT_DIR/index.html"
done
echo "</ul></body></html>" >> "$OUT_DIR/index.html"

echo "📚 Done. View at: $OUT_DIR/index.html"
