#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $PASA="/home/fanyucai/software/PASA/PASApipeline-pasa-v2.2.0/";
my $trinity="/home/fanyucai/software/trinity/trinityrnaseq-Trinity-v2.5.1/Trinity";
my $samtools="/home/fanyucai/software/samtools/samtools-v1.4/bin/";
my $bowtie2="/home/fanyucai/software/bowtie2/bowtie2-2.2.9/";
my $hisat2="/home/fanyucai/software/HISAT2/hisat2-2.1.0/";
my $gmap="/home/fanyucai/software/gmap/gmap-v2015-12-31/bin/";
my $blat="/home/fanyucai/software/blat/";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $env="export PATH=$samtools:$bowtie2:$hisat2:$gmap:$blat:\$PATH";
my($genome,$outdir,@pe1,@pe2,$lines,$strand,$jaccard_clip,$name,$post,$evm);
$outdir||=getcwd;
$strand||="unstranded";
$jaccard_clip||="false";
GetOptions(    
    "a:s{1,}"=>\@pe1,
    "b:s{1,}"=>\@pe2,
    "g:s"=>\$genome,      
    "o:s"=>\$outdir,
    "r:s"=>\$strand,
    "j:s"=>\$jaccard_clip,
    "name:s"=>\$name,
    "post:s"=>\$post,
    "evm:s"=>\$evm,
           );
sub usage{
    print qq{
This script will run Genome-guided Trinity De novo Transcriptome Assembly and  Alignment Assembly.
usage1:
perl $0 -a sampleA.1.fq(.gz),sampleB.1.fq(.gz) -b sampleA.2.fq(.gz),sampleB.2.fq(.gz) -g genome.fa -o $outdir -name species

options:
-a              5 reads fastq (RNA-seq):several files split by comma
-b              3 reads fastq (RNA-seq):several files split by comma
-g              genome sequence(fasta)
-o              output directory(default:$outdir)
-r              Specify strand-specific information:unstranded(default),FR or RF.
-j              An optional parameter --jaccard_clip in Trinity is used for fungal:true or false(default)

Email:fanyucai1\@126.com
2018.1.5
    };
    exit;
}
if(!@pe1||!@pe2||!$genome||!$strand||!$name)
{
    &usage();
}
system "mkdir -p $outdir/shell";
############################first mapping reads to genome by hisat2(https://ccb.jhu.edu/software/hisat2/manual.shtml)
system "mkdir -p $outdir/Hisat2";
my $ref=basename $genome;
open(HISAT,">$outdir/shell/hisat2.sh");
$lines=`wc -l $outdir/shell/hisat2.sh`;
chomp $lines;
system "ln -s $genome $outdir/Hisat2/reference.fa";
print HISAT "cd $outdir/Hisat2/ && $env && $hisat2/hisat2-build reference.fa reference\n";
if($strand=="RF")
{
    print HISAT "cd $outdir/Hisat2/ && $env && $hisat2/hisat2 -x reference -1 @pe1 -2 @pe2 -p 20 --rna-strandness RF -S hisat2.sam\n";
}
elsif($strand=="FR")
{
    print HISAT "cd $outdir/Hisat2/ && $env && $hisat2/hisat2 -x reference -1 @pe1 -2 @pe2 -p 20 --rna-strandness FR -S hisat2.sam\n";
}
else
{
    print HISAT "cd $outdir/Hisat2/ && $env && $hisat2/hisat2 -x reference -1 @pe1 -2 @pe2 -p 20 -S hisat2.sam\n";
}
print HISAT "cd $outdir/Hisat2/ && $env && samtools view -bS -@ 20 hisat2.sam | samtools sort -@ 20 -o hisat2.sort.bam\n";
system "perl $qsub --ppn 10 --lines $lines $outdir/shell/hisat2.sh";
##########################Trinity assembly from genome-aligned reads (bam file)(https://github.com/trinityrnaseq/RagonInst_Sept2017_Workshop/wiki/genome_guided_trinity)
system "mkdir -p $outdir/trinity";
open(TRI,">$outdir/trinity.sh");
my $para;
if($strand=="RF")
{
    $para.="--SS_lib_type RF ";
}
if($strand=="FR")
{
    $para.="--SS_lib_type FR ";
}
if($jaccard_clip=~/t/i)
{
    $para.=" --jaccard_clip ";
}
print TRI "cd $outdir/trinity/ && $env && $trinity --grid_node_CPU 10 --grid_node_max_memory 50G -genome_guided_bam $outdir/Hisat2/hisat2.sort.bam --CPU 20 --min_kmer_cov 2 --inchworm_cpu 20 --max_memory 300G $para\n";
system "perl $qsub --queue big $outdir/trinity.sh";
############################Running the Alignment Assembly Pipeline(http://pasapipeline.github.io)
system "mkdir -p $outdir/PASA";
system "echo 'MYSQLDB=$name'>$outdir/alignAssembly.config";
system "echo 'validate_alignments_in_db.dbi:--MIN_PERCENT_ALIGNED=75'>>$outdir/alignAssembly.config";
system "echo 'validate_alignments_in_db.dbi:--NUM_BP_PERFECT_SPLICE_BOUNDARY=0'>>$outdir/alignAssembly.config";
system "echo 'subcluster_builder.dbi:-m=50'>>$outdir/alignAssembly.config";
############################
open(PASA,">$outdir/pasa.sh");
$para="";
if($strand=="RF" ||$strand=="FR")
{
    $para.="--transcribed_is_aligned_orient ";
}
if($jaccard_clip=~/t/i)
{
    $para.=" --stringent_alignment_overlap 30.0 ";
}
print PASA "mysql -h big01 -uroot -poebiotech  -e \"drop database $name;\"\n";
print PASA "$env && cd $outdir/PASA && perl $PASA/scripts/Launch_PASA_pipeline.pl -c alignAssembly.config --CPU 15 -C -R -g $genome --ALIGNERS blat,gmap $para\n";
$lines=`wc -l $outdir/pasa.sh`;
chomp $lines;
system "perl $qsub --lines $lines --ppn 5 $outdir/pasa.sh";
############################Extraction of ORFs from PASA assemblies
open(ORF,">$outdir/orf.sh");
print ORF "cd $outdir/PASA && $PASA/scripts/pasa_asmbls_to_training_set.dbi --pasa_transcripts_fasta sample_mydb_pasa.assemblies.fasta --pasa_transcripts_gff3 sample_mydb_pasa.pasa_assemblies.gff3\n";
system "perl $qsub $outdir/orf.sh";

