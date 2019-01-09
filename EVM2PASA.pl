#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $PASA="/home/fanyucai/software/PASA/PASApipeline-pasa-v2.2.0/";
my $env="export PATH=/home/fanyucai/software/blat/:/home/fanyucai/software/gmap/gmap-v2015-12-31/bin:/home/fanyucai/software/FASTA/fasta-36.3.8f/bin/:\$PATH";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my($evm,$outdir,$genome,$name,$transcript);
$outdir||=getcwd;
GetOptions(
    "evm:s"=>\$evm,       
    "g:s"=>\$genome,       
    "name:s"=>\$name,      
    "t:s"=>\$transcript,
    "o:s"=>\$outdir,
           );
sub usage{
    print qq{
This script will fixed the output from EVM and get final gene set.
usage:
perl $0 -evm evm.gff -g genome.fna -o $outdir -t trinity.fa -name sample_mydb_pasa

options:
-evm            the gff file from evm
-g              deonovo genome fasta
-t              transcript fasta
-o              output directory(default:$outdir)
-name           mysql database name in PASA must be given(force,default:sample_mydb_pasa)

Email:fanyucai1\@126.com
2018.2.28
    };
    exit;
}
if(!$name||!$evm||!$genome||!$transcript)
{
    &usage();
}
################
system "echo 'MYSQLDB=$name'>$outdir/alignAssembly.config";
system "echo 'validate_alignments_in_db.dbi:--MIN_PERCENT_ALIGNED=75'>>$outdir/alignAssembly.config";
system "echo 'validate_alignments_in_db.dbi:NUM_BP_PERFECT_SPLICE_BOUNDARY=0'>>$outdir/alignAssembly.config";
###############
system "echo 'MYSQLDB=$name'>$outdir/annotCompare.config";
###############
system "echo 'cd $outdir && $PASA/scripts/Load_Current_Gene_Annotations.dbi -c alignAssembly.config -g $genome -P $evm'>$outdir/evm.post.sh";
system "echo 'cd $outdir && $env && perl $PASA/scripts/Launch_PASA_pipeline.pl -c annotCompare.config -A  -g $genome -t $transcript --CPU 50 -L --annots_gff3 $evm'>>$outdir/evm.post.sh";

`perl $qsub --queue fat --lines 2 --ppn 5 $outdir/evm.post.sh`;
