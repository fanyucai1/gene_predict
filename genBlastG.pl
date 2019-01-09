#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $genBlast="/home/fanyucai/software/genBlast/genblast_v139/";
my $blast="/home/fanyucai/software/blast/blast-2.2.26/bin/";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $env="export LD_LIBRARY_PATH=/home/fanyucai/software/gcc/gcc-v6.1.0/lib64/:\$LD_LIBRARY_PATH";
my($genome,$protein,$outdir,$evalue,$coverage);
$outdir||=getcwd;
GetOptions(
    "g:s"=>\$genome,       
    "p:s"=>\$protein,     
    "o:s"=>\$outdir,
    "e:s"=>\$evalue,
    "c:s"=>\$coverage,
           );
sub usage{
    print qq{
This script will use genblast to predict gene.
usage:
perl $0 -g genome.fa -p protein_ref.fasta -o $outdir
options:
-g          genome sequence
-p          protein sequence from reference(you could choose from :/public/land/database/UniProt_taxonomic_divisions/)
-o          output directory(default:$outdir)


Email:fanyucai1\@126.com
2018.1.16
    };
    exit;
}
if(!$genome||!$protein)
{
    &usage();
}
###################################Blast binaries must be present in the same directory as genBlastG
if(! -e "$genBlast/blastall")
{
    system "ln -s $blast/* $genBlast";
}
system "mkdir -p $outdir/genBlast/";
system "ln -s $genBlast/alignscore.txt $outdir/genBlast/alignscore.txt";
system "ln -s $protein $outdir/genBlast/protein.fa";
####################################
system "ln -s $genome $outdir/genBlast/genome.fa";
system "echo '$env && export GBLAST_PATH=$genBlast/ && cd $outdir/genBlast && $genBlast/genblast -p genblastg -q protein.fa -t genome.fa -d 60000 -g T -f F -r 1 -norepair -gff -o genBlast'>$outdir/genBlast.sh";
`perl $qsub --ppn 4 --queue big --lines 2 $outdir/genBlast.sh`;
my @gff=glob "$outdir/genBlast/genBlast*gff";
system "sed -i \"s:coding_exon:exon:g\" $gff[0]";
system "sed -i \"s:transcript:mRNA:g\" $gff[0]";
system "mv $gff[0] $outdir/genBlast.gff";
