#!/bin/sh

# Variables
ENVIRONMENT=master
SPACE_ID="tmqu5vj33f7w"
CONTENT_TYPE="changelog"

gh release view >> release.txt
heading=$(awk -F'title:' '{print $2}'  release.txt | xargs echo -n)
url=$(awk -F'url:' '{print $2}'  release.txt | xargs echo -n) 
body=$(sed '1,/^--$/d' release.txt)  
rm release.txt

curl -X "POST" "https://api.contentful.com/spaces/${SPACE_ID}/environments/${ENVIRONMENT}/entries" --include \
--header "Authorization: Bearer $1" \
--header 'Content-Type: application/vnd.contentful.management.v1+json' \
--header "X-Contentful-Content-Type: ${CONTENT_TYPE}" \
--data-binary "{
  \"fields\": {
    \"heading\": {
      \"en-US\": \"${heading}\"
    },
    \"body\": {
      \"en-US\": \"${body}\nFor more information, see the [release notes](${url}).\"
    },
    \"product\": {
      \"en-US\": [\"Platform\"]
    },
    \"tags\": {
      \"en-US\": [\"Tink Link\"]
    }
  }
}"