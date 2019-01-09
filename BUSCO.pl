#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd;
use Getopt::Long;

my $BUSCO="/home/fanyucai/software/BUSCO/busco/scripts";
my $python="/home/fanyucai/software/python/Python-v2.7.9/bin/python";
#august\hmmer\blast+
my $env="export PATH=/home/fanyucai/software/Augustus/augustus-v3.2.3/bin:/home/fanyucai/software/blast+/ncbi-blast-2.6.0+/bin/:/home/fanyucai/software/hmmer/hmmer-v3.1b2/bin:/home/fanyucai/software/Augustus/augustus-v3.2.3/scripts/:\$PATH";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
#AUGUSTUS_CONFIG_PATH
my $augustus_config="/home/fanyucai/software/Augustus/augustus-v3.2.3/config";
#BUSO_config
my $buso_config="/home/fanyucai/software/BUSCO/busco/config/config.ini.default";
my($fa,$outdir,$type,$db,$cpu);
GetOptions(
    "fa:s"=>\$fa,
    "o:s"=>\$outdir,
    "db:s"=>\$db,
    "t:s"=>\$type,
    "c:s"=>\$cpu,
           );
$outdir||=getcwd;
$cpu||=16;
sub usage{
    print qq{
BUSCO: assessing genome assembly and annotation completeness with single-copy orthologs.
usage:
perl $0 -fa input.fa -t pro -db /home/fanyucai/software/BUSCO/datasets/Eukaryota/fungi_odb9 -o $outdir

-fa         the sequence(fasta)
-t          sets the assessment MODE: geno(genome), prot(proteins), tran(transcriptome)          
-db         you should choose the dataset from (/home/fanyucai/software/BUSCO/datasets)
-o          output directory(default:$outdir)
-c          cpu number(default:16)

2017.6.20
Email:fanyucai1\@126.com
    };
    exit;
}

if(!$type||!$fa||!$db)
{
    &usage();
}
system "mkdir -p $outdir/tmp";
system "mkdir -p $outdir/BUSCO_summaries/";
system "mkdir -p $outdir/config";
system "ln -s $augustus_config/* $outdir/config";
system "cp $buso_config $outdir/config.ini";

open(BU,">$outdir/busco.sh");
print BU "export BUSCO_CONFIG_FILE=$outdir/config.ini && export AUGUSTUS_CONFIG_PATH=$outdir/config && $env && cd $outdir && $python $BUSCO/run_BUSCO.py -m $type -i $fa -l $db -o BUSCO -t $outdir/tmp -c $cpu\n";
`perl $qsub $outdir/busco.sh`;



system "cp $outdir/run_*/short_summary*.txt $outdir/BUSCO_summaries/";
open(PL,">$outdir/plot.sh");
print PL "export BUSCO_CONFIG_FILE=$outdir/config.ini && export AUGUSTUS_CONFIG_PATH=$outdir/config && $env && $python $BUSCO/generate_plot.py --working_directory $outdir/BUSCO_summaries/\n";
`perl $qsub $outdir/plot.sh`;
