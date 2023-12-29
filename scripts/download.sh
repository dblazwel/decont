# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

url=$1
output_directory=$2
uncompress=$3
filter_word=$4

# Create the directory and download the file
mkdir -p $output_directory
filename=$(basename "$url")
downloaded_file="$output_directory/$filename"

# Check if the file already exists
if [ -e "$downloaded_file" ]; then
    echo "File $downloaded_file already exists. Skipping download."
else
    wget "$url" -P "$output_directory"
fi

# Uncompress (if required)
if [ "$uncompress" == "yes" ]; then
    gunzip "$downloaded_file"
    downloaded_file="${downloaded_file%.gz}"
fi

# Filter the sequences (if required)
if [ -n "$filter_word" ]; then
    # Save the sequence only when Flag = 1. We activate it when the word is found in the header of a sequence, and deactivate it if a heather doesn't contain it.
    awk -v filter="$filter_word" '/^>/ {flag=1} flag && !($0 ~ filter) {print} /^>/ && $0 ~ filter {flag=0}' "$downloaded_file" > "${downloaded_file}_filtered"
fi
