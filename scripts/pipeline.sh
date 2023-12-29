export WD=~/decont

#Download all the files specified in data/filenames
echo "### 01. Download the data"
list_of_urls=$(cat $WD/data/urls)
for url in $list_of_urls
do
    bash $WD/scripts/download.sh "$url" "$WD/data"
done
echo ""

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
echo "### 02. Download the contaminants database"
bash $WD/scripts/download.sh "https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz" "$WD/res" "yes" "small nuclear RNA"
echo ""

# Index the contaminants file
echo "### 03. Index the contaminants file"
#bash $WD/scripts/index.sh "$WD/res/contaminants.fasta_filtered" "$WD/res/contaminants_idx"
echo ""

# Merge the samples into a single file
echo "### 04. Merge the samples"
mkdir -p $WD/out/merged
list_of_sample_ids=$(ls $WD/data | grep -E "\.fastq" | cut -d "-" -f 1 | sort -u)
for sid in $list_of_sample_ids
do
    bash $WD/scripts/merge_fastqs.sh $WD/data $WD/out/merged $sid
    echo "File $sid created in $WD/out/merged"
done
echo ""

# Remove the adapters from the merged samples
echo "### 05. Remove the adapters"
mkdir -p $WD/out/trimmed
mkdir -p $WD/log/cutadapt
list_of_merged_ids=$(ls $WD/out/merged | grep -E "\.fastq")
for sid in $list_of_merged_ids
do
    cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
     -o "$WD/out/trimmed/$sid" "$WD/out/merged/$sid" > "$WD/log/cutadapt/$sid"
done
echo ""


# Align the trimmed files to the contaminants genome
echo "### 06. Align the samples to the contaminants"
list_of_trimmed_ids=$(ls $WD/out/trimmed | grep -E "\.fastq")
for fname in $list_of_trimmed_ids
do
   sid=$(basename "$fname" .fastq.gz)
   mkdir -p $WD/out/star/$sid
   STAR --runThreadN 4 --genomeDir "$WD/res/contaminants_idx" \
        --outReadsUnmapped Fastx --readFilesIn "$WD/out/trimmed/$fname" \
        --readFilesCommand gunzip -c --outFileNamePrefix "$WD/out/star/$sid/"
done 
echo ""

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

echo "Decontamination completed"
