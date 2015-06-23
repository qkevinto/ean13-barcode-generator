#!/usr/bin/perl -w

use strict;

open(PS,'barcode.ps') || die 'File not found';
$_ = join('',<PS>);
close(PS);
m/
    %\ --BEGIN\ TEMPLATE--
    (.*)
    %\ --END\ TEMPLATE--
    /sx || die 'Unable to parse out the template';
my $template = '';
$template .= "%!PS-Adobe-2.0 EPSF-2.0\n";
$template .= "%%BoundingBox: 0 0 [% width %] [% height %]\n";
$template .= "%%EndComments";
$template .= $1;
$template .= "2 2 scale\n";
$template .= "10 7 moveto\n";
$template .= "[% call %]\n";
$template .= "showpage\n";

open(IN,'input.csv');
my @items=<IN>;
close(IN);

foreach $_ (@items) {
    m/^(.*),(.*),(.*)$/ || die "Bad line: $_";
    my $name = $1;
    my $ean13 = $2;
    $name =~ s/[^\w]/_/g;
    my $fileformat = "eps";
    my $prefix = "";
    my $suffix = "barcode";
    my $filename = lc("$prefix$name$suffix.$fileformat");
    my $width = "232";
    my $height = "153";
    my $contents = "($ean13) (includetext guardwhitespace) /ean13 /uk.co.terryburton.bwipp findresource exec";
    my $barcode = $template;
    $barcode =~ s/\[% call %\]/$contents/;
    $barcode =~ s/\[% width %\]/$width/;
    $barcode =~ s/\[% height %\]/$height/;
    open(OUT,">", "barcodes/$filename");
    print OUT $barcode;
    close(OUT);
}
