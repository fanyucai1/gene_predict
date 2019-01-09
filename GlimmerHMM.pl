#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd;

my $GlimmerHMM="/home/fanyucai/software/GlimmerHMM/GlimmerHMM/sources/glimmerhmm";
my $trainHMM="/home/fanyucai/software/GlimmerHMM/GlimmerHMM/train/trainGlimmerHMM";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my($ref,$scaffold,$outdir,$gff);
$outdir||=getcwd;
GetOptions(
    "r:s"=>\$ref,       
    "c:s"=>\$scaffold,      
    "g:s"=>\$gff,
    "o:s"=>\$outdir,
           );
sub usage{
    print qq{
This script will use GlimmerHMM to predict gene structure.
usage:
perl $0 -c contig.fa -r reference.fa -g ref.gff -o $outdir
options:
-c              your genome sequence
-r              reference genome sequence
-g              reference gff file
-o              output directory(default:$outdir)
    
Email:fanyucai1\@126.com
2017.12.27
    };
    exit;
}
if(!$gff)
{
    &usage();
}
system "mkdir -p $outdir";
##########################get exon file (https://ccb.jhu.edu/software/glimmerhmm/man.shtml)
open(GFF,"$gff");
open(EXON,">$outdir/exon.file");
my (%hash,$j);
my $num=0;
my $run=0;
while(<GFF>)
{
    chomp;
    my @array=split;
    if($_!~/#/ && $#array>2)
    {
        if($array[2]=~"mRNA")
        {
            $run=1;
            $num++;
            if($num>1)
            {
                print EXON "\n";
            }
        }
        if($array[2]=~"gene"||$array[2]=~"cDNA_match"||$array[2]=~"lnc_RNA"||$array[2]=~"pseudogene"||$array[2]=~"tRNA"||$array[2]=~"transcript")
        {
            $run=0;
        }
        if($array[2]=~/exon/i && $run==1)
        {
            $j++;
            if($j==1)
            {
                if($array[6]=~"-" && ($array[4] >$array[3]))
                {
                     print EXON "$array[0] $array[4] $array[3]";
                }
                else
                {
                    print EXON "$array[0] $array[3] $array[4]";
                }
            }
            else
            {
                if($array[6]=~"-")
                {
                    print EXON "\n$array[0] $array[4] $array[3]";
                }
                else
                {
                    print EXON "\n$array[0] $array[3] $array[4]";
                }
            }
        }
    }
}
##########################Training GlimmerHMM
system "awk \'{print \$1}\' $ref >$outdir/reference.fna";
system "echo 'cd $outdir && $trainHMM reference.fna $outdir/exon.file' >$outdir/train.sh";
system "perl $qsub --ppn 10 $outdir/train.sh";
#########################run GlimmerHMM
my @array=glob("$outdir/TrainGlimmM*");
my $dir;
foreach my $key(@array)
{
    my @array2=split(/\//,$key);
    if($array2[$#array2]!~"log")
    {
        $dir=$array2[$#array2];
    }
}
system "echo 'cd $outdir && $GlimmerHMM $scaffold $dir -g -o glimmerHMM.gff'>$outdir/glimmerhmm.sh";
system "cd $outdir && perl $qsub --ppn 8 $outdir/glimmerhmm.sh";
