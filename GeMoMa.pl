#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd;
use File::Basename;

my $GeMoMa="/home/fanyucai/software/GeMoMa";
my $blast="/home/fanyucai/software/blast+/ncbi-blast-2.6.0+/bin";
my $env="export PATH=$GeMoMa:$blast:\$PATH";
my $qsub="/home/fanyucai/software/qsub/qsub-pbs.pl";
my ($outdir,$denovo,$bam,$ref,$gff,$lib);
$outdir||=getcwd;

GetOptions(
    "d:s"=>\$denovo,
    "gff:s"=>\$gff,
    "ref:s"=>\$ref,       
    "o:s"=>\$outdir,
    "bam:s"=>\$bam,
    "lib:s"=>\$lib,
           );

sub usage{
    print qq{
This script will use GeMoMa to predict gene.
usage:
perl $0 -d scaffold.fna -gff reference.gff -ref ref.fna -o $outdir
                    or
perl $0 -d scaffold.fna -gff reference.gff -ref ref.fna -bam RNAseq.bam -o $outdir
options:
-d              the genome of the target organism (FastA)
-gff            the annotation of the reference organism (GFF/GTF)
-ref            the genome of the reference organism (FastA)
-bam            mapped-reads are the mapped RNA-seq reads (SAM/BAM)
-lib            the RNA-seq library type({FR_UNSTRANDED, FR_FIRST_STRAND, FR_SECOND_STRAND})
-o              output directory(default:$outdir)

Email:fanyucai1\@126.com
2018.2.27
    };
    exit;
}
if(!$denovo||!$gff||!$ref)
{
    &usage();
}

system "awk \'{print \$1}\' $ref >$outdir/refe.fna";
system "cp $GeMoMa/run.sh $outdir";
system "sed -i 's:GeMoMa-:$GeMoMa/GeMoMa-:g' $outdir/run.sh";
if($lib && $bam)
{
    system "echo 'cd $outdir && $env && ./run.sh $gff refe.fna $denovo $outdir $lib $bam'>$outdir/GeMoMa.sh";
}
else
{
    system "echo 'cd $outdir && $env && ./run.sh $gff refe.fna $denovo $outdir'>$outdir/GeMoMa.sh";
}
system "echo 'cd $outdir && sed -i \'s/GAF/GeMoMa/\' filtered_predictions.gff'>>$outdir/GeMoMa.sh";
my $line=`wc -l $outdir/GeMoMa.sh`;
chomp($line);
#`perl $qsub --lines $line`;


