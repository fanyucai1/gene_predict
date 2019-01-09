#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use File::Basename;
use Cwd;

########convert gff to zff
my $MAKER="/home/fanyucai/software/MAKER/maker/bin/maker2zff";
my $Zoe="export ZOE=/home/fanyucai/software/MAKER/SNAP-master/Zoe";
my $SNAP="/home/fanyucai/software/MAKER/SNAP-master/";
my $env="export PATH=/lustre/Work/fanyucai/software/cdbfasta/cdbfasta-master:\$PATH && export PERL5LIB=/home/fanyucai/software/TransDecoder/TransDecoder-3.0.1/PerlLib:/home/fanyucai/software/PASA/PASApipeline-pasa-v2.2.0/PerlLib:\$PERL5LIB";
my $zff2gff="/home/fanyucai/script/SNAP_output_to_gff3.pl";#https://github.com/genomecuration/JAMg/tree/master/bin
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my($gff,$ref,$outdir,$contig,$queue);
$queue||="all";
$outdir||=getcwd;
GetOptions(
    "gff:s"=>\$gff,
    "o:s"=>\$outdir,
    "ref:s"=>\$ref,       
    "contig:s"=>\$contig,
    "queue:s"=>\$queue,
           );
sub usage{
    print qq{
This script will use SNAP to predict gene.
usage:
perl $0 -ref reference.fna -gff ref.gff -contig contig.fa
options:
-ref                reference genome file
-gff                reference gff file
-contig             assembly sequence
-queue              which queue you will run
-o                  output directory

Email:fanyucai1\@126.com
2018.1.29
    };
    exit;
}
if(!$gff||!$ref||!$contig)
{
    &usage();
}

##################prepare the SNAP
system "mkdir -p $outdir/SNAP";
open(SNAP,">$outdir/prepare.sh");
print SNAP "cp $gff $outdir/SNAP/ref.gff && ";
print SNAP "cd $outdir/SNAP && $Zoe && $MAKER ref.gff\n";
`perl $qsub $outdir/prepare.sh`;

#################
open(D1,"$outdir/SNAP/genome.dna");
open(D2,"$ref");
my (%hash,$seqname);
while(<D2>)
{
    chomp;
    if($_=~/\>/)
    {
        $seqname=$_;
    }
    else
    {
        $hash{$seqname}.=$_;
    }
}
open(R1,">$outdir/SNAP/new.dna");
while(<D1>)
{
    chomp;
    if($_=~/\>/)
    {
        if(exists $hash{$_})
        {
            print R1 $_,"\n",$hash{$_},"\n";
        }
    }
}
system "mv $outdir/SNAP/new.dna $outdir/SNAP/genome.dna";
system "echo 'cd $outdir/SNAP && $Zoe && $SNAP/fathom genome.ann genome.dna -categorize 1000'>$outdir/SNAP.sh";
system "echo 'cd $outdir/SNAP && $SNAP/fathom uni.ann uni.dna -export 1000 -plus'>>$outdir/SNAP.sh";
system "echo 'cd $outdir/SNAP && $Zoe && $SNAP/forge export.ann export.dna'>>$outdir/SNAP.sh";
system "echo 'cd $outdir/SNAP && perl $SNAP/hmm-assembler.pl test . > test.hmm'>>$outdir/SNAP.sh";
system "echo 'cd $outdir/SNAP && $SNAP/snap test.hmm $contig >$outdir/SNAP.zff'>>$outdir/SNAP.sh";
my $lines=`wc -l $outdir/SNAP.sh`;
chomp($lines);
`perl $qsub --lines $lines $outdir/SNAP.sh`;

open(ZFF,"$outdir/SNAP.zff");
open(ZFF2,">$outdir/SNAP.zff2");
while(<ZFF>)
{
    chomp;
    if($_!~/scoring....decoding/)
    {
        print ZFF2 $_,"\n";
    }
}
system "mv $outdir/SNAP.zff2 $outdir/SNAP.zff";
system "echo '$env && cd $outdir/ && perl $zff2gff SNAP.zff $contig >$outdir/SNAP.gff3'>$outdir/zff2gff.sh";
`perl $qsub $outdir/zff2gff.sh`;
