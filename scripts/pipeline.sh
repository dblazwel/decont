export WD=~/decont

#Download all the files specified in data/filenames
list_of_urls=$(cat $WD/data/urls)
for url in $list_of_urls
do
    bash $WD/scripts/download.sh "$url" "$WD/data"
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash $WD/scripts/download.sh "https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz" "$WD/res" "yes" "small nuclear RNA"

# Index the contaminants file
#bash $WD/scripts/index.sh "$WD/res/contaminants.fasta_filtered" "$WD/res/contaminants_idx"

# Merge the samples into a single file
mkdir -p $WD/out/merged
list_of_sample_ids=$(ls $WD/data | grep -E "\.fastq" | cut -d "-" -f 1 | sort -u)
for sid in $list_of_sample_ids
do
    bash $WD/scripts/merge_fastqs.sh $WD/data $WD/out/merged $sid
done

# Remove the adapters from the merged samples
mkdir -p $WD/out/trimmed
mkdir -p $WD/log/trimmed
list_of_merged_ids=$(ls $WD/out/merged)
for sid in $list_of_merged_ids
do
    cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
     -o "$WD/out/trimmed/$sid" "$WD/out/merged/$sid" > "$WD/log/cutadapt/$sid"
done


# TODO: run STAR for all trimmed files
#for fname in out/trimmed/*.fastq.gz
#do
    # you will need to obtain the sample ID from the filename
#    sid=#TODO
    # mkdir -p out/star/$sid
    # STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    #    --outReadsUnmapped Fastx --readFilesIn <input_file> \
    #    --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
#done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
