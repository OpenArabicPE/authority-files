#!/usr/bin/env bash
# set -x #echo each command for debug
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
cd $current_dir && pwd

# name of an external SPARQL query for establishing the items to be downloaded
# variable names are "item" und "itemLabel"
SPARQL=wikidata_arabic-periodicals.rq

# designate a descriptive tag for this project
TAG="arabic-periodicals"
# Set the target directory using the current date.
# NOTE: all folders and files are relative to the PWD you are working from.
target_dir=../data/wikidata
cd $target_dir && pwd


SAVEDIR=$(date -Idate)_$TAG
# Define the output file name for the list of Wikidata items.
ITEMLIST=${SAVEDIR}_wikidata-items.json

# Define a function to display a progress bar.
function ProgressBar {
  # Calculate the progress percentage.
  _progress=$(( ${2} * 100 / ${3} ))
  _done=$(( _progress*4 / 10 ))  # Calculate the number of completed blocks.
  _left=$(( ${1} - _done ))     # Calculate the number of remaining blocks.

  # Build the progress bar string lengths.
  _done=$(printf "%${_done}s")
  _left=$(printf "%${_left}s")

  # Print the progress bar.
  printf "[%s%s]" "${_done// /#}" "${_left// /-}"
}

######
# Set the terminal width using the $COLUMNS variable or tput command.
WIDTH=$COLUMNS
if command -v tput &> /dev/null; then
  WIDTH=$(tput cols)
fi

# Download the list of items from Wikidata using SPARQL query.
echo -n "Downloading list of items from Wikidata"
curl -s -H "Accept: application/sparql-results+json" --data-urlencode "query@$SPARQL"  https://query.wikidata.org/sparql \
  | jq -c '.results.bindings | sort_by(.itemLabel.value) | .[] | {"name": .itemLabel.value, "item": .item.value}' \
  > "$ITEMLIST"
echo "DONE!"

# check if target directory exists. if not, create it.
if [ ! -e "${SAVEDIR}" ]; then
  mkdir "${SAVEDIR}"
fi

# iterate over the list of items and download them as LOD
NUMITEMS=$(wc -l < "$ITEMLIST")
i=1

# Print a message indicating the number of tools to be downloaded.
printf "Downloaded %i items. Getting properties.\n" "${NUMITEMS}"

# Iterate through each tool in the list and download its properties.
while IFS= read -r item
do
  # Extract the tool ID and name from the JSON object.
  itemId=$(echo "$item" | jq -r '.item' | sed 's/^.*entity\/\(.*\)$/\1/')
  itemName=$(echo "$item" | jq -r '.name')

  # Construct file names for the tool's properties in different formats.
  itemFile=${SAVEDIR}/${itemId} #_${itemName// /_}
  itemFileJSON="${itemFile}.unstable.json"
  itemFileJSONLD="${itemFile}.jsonld"
  itemFileTTL="${itemFile}.ttl"

  # Print a progress message with the tool name and percentage complete.
  printf "\r%-${WIDTH}s\r" "$(printf "$(ProgressBar 50 ${i} "${NUMITEMS}") Downloading items (%i/%i) %s" "${i}" "${NUMITEMS}" "${itemName}")"

  # If running in non-interactive mode, print a newline character.
  if [ "${DEBIAN_FRONTEND}" = "noninteractive" ]; then
    echo ""
  fi

  # Download the tool's properties in different formats using curl.
  curl -s -X'GET' \
    "https://www.wikidata.org/w/rest.php/wikibase/v0/entities/items/${itemId}" \
    -H 'accept: application/json' > "$itemFileJSON"
  curl -s -X'GET' \
    "https://www.wikidata.org/wiki/Special:EntityData/${itemId}.jsonld" \
    > "$itemFileJSONLD"
  curl -s -X'GET' \
    "https://www.wikidata.org/wiki/Special:EntityData/${itemId}.ttl" \
    > "$itemFileTTL"
  i=$(( i + 1 ))
done < "$ITEMLIST"
echo ""

# Print a final message indicating that all downloads are complete.
echo "ALL DONE. Creating .tar.bz2"

# Create a tarball of the downloaded files and compress it using bzip2.
tar cf - "$ITEMLIST" "$SAVEDIR" \
  | bzip2 -c -9 -q -z - > "${SAVEDIR}.tar.bz2"

echo "Saved all $NUMITEMS items in $SAVEDIR.tar.bz2"
