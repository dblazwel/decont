# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <genomefile> <outdir>"
    exit 1
fi

genomefile=$1
outdir=$2

if [ -e "$outdir/SAindex" ] || [ -e "$outdir/sa" ] || [ -e "$outdir/sjdb" ] || [ -e "$outdir/genomeParameters.txt" ]; then
    echo "The output already exists in $outdir. Skipping index."
else
	mkdir -p "$outdir"

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.
	STAR --runThreadN 4 --runMode genomeGenerate --genomeDir "$outdir" \
     	     --genomeFastaFiles "$genomefile" --genomeSAindexNbases 9
fi
