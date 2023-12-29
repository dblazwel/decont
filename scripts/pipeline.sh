export WD=~/decont
echo ""
#Download all the files specified in data/filenames
echo "### 01. Download the data"
#list_of_urls=$(cat $WD/data/urls)
#for url in $list_of_urls
#do
#    bash $WD/scripts/download.sh "$url" "$WD/data"
#done
# Replace the loop with a wget one-liner
wget --directory-prefix="$WD/data" --input-file="$WD/data/urls" -P "$WD/data" --no-clobber
echo ""

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
echo "### 02. Download the contaminants database"
bash $WD/scripts/download.sh "https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz" "$WD/res" "yes" "small nuclear RNA"
echo ""

# Index the contaminants file
echo "### 03. Index the contaminants file"
bash $WD/scripts/index.sh "$WD/res/contaminants.fasta_filtered" "$WD/res/contaminants_idx"
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
     -o "$WD/out/trimmed/$sid" "$WD/out/merged/$sid" > "$WD/log/cutadapt/$sid.log" 2>&1
    echo "Sample $sid merged."
done
echo ""


# Align the trimmed files to the contaminants genome
echo "### 06. Align the samples to the contaminants"
list_of_trimmed_ids=$(ls $WD/out/trimmed | grep -E "\.fastq")
for fname in $list_of_trimmed_ids
do
   sid=$(basename "$fname" .fastq.gz)
   output_dir="$WD/out/star/$sid"
   if [ -d "$output_dir" ]; then
      echo "The directory $output_dir already exists. Skipping alignement for $sid."
   else
   	mkdir -p $WD/out/star/$sid
   	STAR --runThreadN 4 --genomeDir "$WD/res/contaminants_idx" \
             --outReadsUnmapped Fastx --readFilesIn "$WD/out/trimmed/$fname" \
             --readFilesCommand gunzip -c --outFileNamePrefix "$WD/out/star/$sid/"
   fi
done 
echo ""

# Log file
mkdir -p $WD/log
log_file="$WD/log/pipeline.log"
current_date_time=$(date "+%d-%m-%Y %H:%M:%S")
echo "=== Decontamination: $current_date_time ===" >> "$log_file"
# - cutadapt: Reads with adapters and total basepairs
list_cutadapt=$(ls $WD/log/cutadapt | grep -E "\.fastq")
for sid in $list_cutadapt
do
   echo "=== Cutadapt Log $sid ===" >> "$log_file"
   grep "Reads with adapters:" "$WD/log/cutadapt/$sid" >> "$log_file"
   grep "Total basepairs processed:" "$WD/log/cutadapt/$sid" >> "$log_file"
done
echo "" >> "$log_file"
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
list_star=$(ls $WD/out/star)
for dir in $list_star
do
   echo "=== STAR Log $dir ===" >> "$log_file"
   grep "Uniquely mapped reads %" "$WD/out/star/$dir/Log.final.out" >> "$log_file"
   grep "% of reads mapped to multiple loci" "$WD/out/star/$dir/Log.final.out" >> "$log_file"
   grep "% of reads mapped to too many loci" "$WD/out/star/$dir/Log.final.out" >> "$log_file"
done
echo "" >> "$log_file"

echo "Decontamination completed"
