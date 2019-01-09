#!/usr/bin/perl -w
use strict;
use warnings;
use Cwd;
use FindBin qw($Bin);
use Getopt::Long;

my $fragscaff="/home/fanyucai/software/FragScaff";
my $gcc="/home/fanyucai/software/gcc/gcc-v4.9.4/lib64";
my $longranger="/home/fanyucai/software/Long_Ranger/longranger-2.1.3/longranger";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $samtools="/home/fanyucai/software/samtools/samtools-v1.4/bin/samtools";

my($contig,$outdir,$pe1,$pe2,$prefix);
GetOptions(
     "contig:s"=>\$contig,
     "o:s"=>\$outdir,
     "pe1:s"=>\$pe1,
     "pe2:s"=>\$pe2,
     "p:s"=>\$prefix,
           );
sub usage{
    print qq{
This script will scaffold the contig using long_ranger and fragscaff.
usage:
perl $0 -fa 
options:
-contig     the fasta file of contig
-o          output directory
-pe1        the fastq file 5' reads
-pe2        the fastq file 3' reads
-p          the prefix of output

Email:fanyucai1\@126.com
2017.5.
    };
    exit;
}

system "mkdir -p $outdir/contig/";
system "mkdir -p $outdir/fastq/";
system "ln -s $contig $outdir/contig/";
system "ln -s $pe1 $outdir/fastq/";
system "ln -s $pe2 $outdir/fastq/";

#index the contig
open(REF,">$outdir/ref_index.sh");
print REF "cd $outdir/contig && $longranger ref $contig";
`perl $qsub $outdir/ref_index.sh`;

#mapping
open(MAP,">$outdir/mapping.sh");
print MAP "cd $outdir && $longranger --reference=$outdir/contig/ --fastqs $outdir/fastq/";
`perl $qsub $outdir/mapping.sh`;

#scaffold
open(SCA,">$outdir/fragScaff.sh");
print SCA "cd $outdir && perl $fragscaff/fragScaff.pl -B $outdir/possorted_bam.bam";