#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $EVM="/home/fanyucai/software/EVM/EVidenceModeler-1.1.1/";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my $gffread="/home/fanyucai/software/gffread/gffread/gffread";
my ($outdir,$ab,$genome,$met,$pro,$tra,$score);
$outdir||=getcwd;
$score||=3;
GetOptions(
    "a:s"=>\$ab,
    "p:s"=>\$pro,
    "t:s"=>\$tra,
    "g:s"=>\$genome,
    "o:s"=>\$outdir,
           );
sub usage{
    print qq{
Combine ab intio gene predictions and protein and transcript alignments into weighted consensus gene structures using EVM.
usage:
perl $0 -a ab_predict.gff -p protein.gff -t pasa.gff3 -g genome.fasta

options:
-a          gff file from abinitio
-p          gff file output from GeMoMa
-t          gff file output from PASA
-g          genome sequence(fasta)
-score      default:5
-o          output directory

Email:fanyucai1\@126.com
2018.3.28
    };
    exit;
}
if(!$genome)
{
    &usage();
}
system "mkdir -p $outdir";
my $para.=" --gene_predictions $ab ";
$para.=" --transcript_alignments $tra ";
$para.=" ----protein_alignments $pro ";
########################################weight.txt
open(WE,">$outdir/weight.txt");
print WE "ABINITIO_PREDICTION\tGeneMark.hmm\t1\n";
print WE "PROTEIN\tGeMoMa\t5\n";
print WE "ABINITIO_PREDICTION\tAUGUSTUS\t1\n";
print WE "ABINITIO_PREDICTION\tsnap\t1\n";
print WE "TRANSCRIPT\tassembler-sample_mydb_pasa\t10\n";
print WE "OTHER_PREDICTION\ttransdecoder\t8\n";
#################################################
open(SH,">$outdir/run.sh");
print SH "cd $outdir && perl $EVM/EvmUtils/partition_EVM_inputs.pl --genome $genome $para --segmentSize 100000 --overlapSize 10000 --partition_listing $outdir/partitions_list.out\n";
print SH "cd $outdir && perl $EVM/EvmUtils/write_EVM_commands.pl $para --genome $genome --weights $outdir/weight.txt --output_file_name evm.out --partitions $outdir/partitions_list.out >$outdir/commands.list\n";
system "perl $qsub --lines 2 $outdir/run.sh";
system "cd $outdir && perl $qsub --lines 50 --maxproc 40 commands.list";
##################################################Combine the Partitions and Convert to GFF3 Format
open(SH2,">$outdir/run2.sh");
print SH2 "cd $outdir && perl $EVM/EvmUtils/recombine_EVM_partial_outputs.pl --partitions partitions_list.out --output_file_name evm.out\n";
system "perl $qsub $outdir/run2.sh";
my @evm=glob("$outdir/*/evm.out");
foreach my $key(@evm)
{
    open(EVM,$key);
    open(OUT,">$key.bak");
    my $gene="";
    my $threshold=0;
    while(<EVM>)
    {
        chomp;
        if($_=~/^#/)
        {
            $threshold=0;
            if($gene=~/AUGUSTUS/i)
            {
                $threshold++;
            }
            if($gene=~/GeMoMa/i)
            {
                $threshold=$threshold+5;
            }
            if($gene=~/GeneMark.hmm/i)
            {
                $threshold++;
            }
            if($gene=~/snap/i)
            {
                $threshold++;
            }
            if($gene=~/assembler-sample_mydb_pasa/i)
            {
                $threshold=$threshold+10;
            }
            if($gene=~/transdecoder/i)
            {
                $threshold=$threshold+8;
            }
            if($threshold >=$score)
            {
                print OUT $gene;
            }
            $gene="";
        }
        if($_!~/^\s+/)
        {
            $gene.="$_\n";
        }
    }
    $threshold=0;
    if($gene=~/AUGUSTUS/i)
    {
        $threshold++;
    }
    if($gene=~/GeMoMa/i)
    {
        $threshold=$threshold+5;
    }
    if($gene=~/GeneMark.hmm/i)
    {
        $threshold++;
    }
    if($gene=~/snap/i)
    {
        $threshold++;
    }
    if($gene=~/assembler-sample_mydb_pasa/i)
    {
        $threshold=$threshold+10;
    }
    if($gene=~/transdecoder/i)
    {
        $threshold=$threshold+8;
    }
    if($threshold >=$score)
    {
        print OUT $gene;
    }
    close EVM;
    close OUT;
    system "mv $key $key.temp";
    system "mv $key.bak $key";
}

open(SH3,">$outdir/run3.sh");
print SH3 "cd $outdir && perl $EVM/EvmUtils/convert_EVM_outputs_to_GFF3.pl  --partitions partitions_list.out --output evm.out --genome $genome\n";
print SH3 "cd $outdir && find . -regex \".*evm.out.gff3\" -exec cat {} \\; > EVM.all.gff3\n";
system "perl $qsub --lines 2 $outdir/run3.sh";

#get cds and protein
system "$gffread $outdir/EVM.all.gff3 -g $genome -x $outdir/cds.fasta -y $outdir/protein.fasta";
