#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd;

my $augustus="/home/fanyucai/software/Augustus/augustus-v3.2.3/";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $env="export PATH=$augustus/bin/:\$PATH && export AUGUSTUS_CONFIG_PATH=$augustus/config/";
my ($ref,$gff,$outdir,$scaffold,$protein,$species);
$outdir||=getcwd;
GetOptions(
    "ref:s"=>\$ref,       
    "gff:s"=>\$gff,       
    "scaf:s"=>\$scaffold,
    "o:s"=>\$outdir,
    "species:s"=>\$species,
           );
sub usage{
    print qq{
This script will train and  run Augustus to predict gene.
usage:
########train && predict
perl $0 -ref ref.fna -gff ref.gff -scaf scaffold.fasta -species spceiesname
        or
########only predict gene
perl $0 -scaf scaffold.fasta -species spceiesname
options：
-ref            reference sequence fasta
-gff            gff file
-scaf           your assembly sequence
-species        species name as used by AUGUSTUS              

Email:fanyucai1\@126.com
2018.2.6
    };
    exit;
}
if(!$species)
{
    &usage();
}
#########################
if($ref && $gff)
{
    system "awk \'{print \$1}\' $ref >reference.fna";
    open(TR,">$outdir/train.sh");
    print TR "$env && perl $augustus/scripts/autoAugTrain.pl --genome=$outdir/reference.fna --trainingset=$gff --species=$species --workingdir=$outdir\n";
    `perl $qsub $outdir/train.sh`;
}

open(PR,">$outdir/run.sh");
print PR "cd $outdir && $augustus/bin/augustus --strand=both  --genemodel=complete --uniqueGeneId=true --noInFrameStop=true --gff3=on --AUGUSTUS_CONFIG_PATH=$augustus/config/ --outfile=augustus_complete.gff --species=$species  $scaffold\n";

`perl $qsub $outdir/run.sh`;

