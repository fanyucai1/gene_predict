#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $FGMP="/home/fanyucai/software/FGMP/FGMP-2.0-hyphaltip_audit";
my $blast="/home/fanyucai/software/blast+/ncbi-blast-2.6.0+/bin/";
my $hmmer="/home/fanyucai/software/hmmer/hmmer-v3.1b2/bin/";
my $EMBOSS="/home/fanyucai/software/EMBOSS/EMBOSS-v6.5.7/bin/";
my $Exonerate="/home/fanyucai/software/Exonerate/exonerate-2.2.0-x86_64/bin/";
my $augustus="/home/fanyucai/software/Augustus/augustus-v3.2.3/bin/";
my $env ="export FGMP=\$FGMP && export PERL5LIB=\$PERL5LIB:\$FGMP/lib && export PATH=$augustus:$Exonerate:$blast:$hmmer:$EMBOSS:\$PATH";
my($genome,$outdir,$queue,$thread);
$queue||="all";
$outdir||=getcwd;
$thread||=10;

GetOptions(
    "t:s"=>\$thread,       
    "queue:s"=>\$queue,       
    "o:s"=>\$outdir,
    "genome:s"=>\$genome,
           );
sub usage{
    print qq{
This script will assess fungal genome completeness and gene content.
usage:
perl $0 -genome contig.fa -o $outdir -t 10 -queue all
options:
-genome             genome in fasta format
-o                  output directory(default:$outdir)
-t                  Specify the number of processor threads to use(default:10)
-queue              which queue you will run(defualt:all)

Email:fanyucai1\@126.com
2017.12.14
    };
   exit; 
}
if(!$genome)
{
    &usage();
}
system "mkdir -p $outdir/FGMP";
system "ln -s $genome $outdir/FGMP/";
my $filename= basename $genome;
system "echo 'FGMP=$FGMP'>$outdir/FGMP/fgmp.config";
system "echo 'WRKDIR=$outdir/FGMP'>>$outdir/FGMP/fgmp.config";
system "echo 'BLASTX=blastx'>>$outdir/FGMP/fgmp.config";
system "echo 'EXONERATE=exonerate'>>$outdir/FGMP/fgmp.config";
system "echo 'SIXPACK=sixpack'>>$outdir/FGMP/fgmp.config";
system "echo 'HMMER=hmmsearch'>>$outdir/FGMP/fgmp.config";
system "echo 'TBLASTN=tblastn'>>$outdir/FGMP/fgmp.config";
system "echo 'MAKEBLASTDB=makeblastdb'>>$outdir/FGMP/fgmp.config";
system "echo 'AUGUSTUSPATH=augustus'>>$outdir/FGMP/fgmp.config";
system "chmod 755 -R $outdir/FGMP/";
system "echo 'cd $outdir/FGMP && $env && export FGMPTMP=$outdir && perl $FGMP/fgmp.pl -g $filename -T $thread '>$outdir/FGMP.sh";
system "perl $qsub --queue $queue --ppn 3 $outdir/FGMP.sh";










