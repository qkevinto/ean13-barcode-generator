#!/usr/bin/perl -w

use strict;
use warnings;

my $template;
my $prefix = "";
my $suffix = "_barcode";
my $width = "232";
my $height = "153";
my $directory = "barcodes";
my $fileFormat = "eps";

# Initialises the main barcode template
sub initTemplate {
  open(PS,'barcode.ps') || die 'File not found';
  $_ = join('',<PS>);
  close(PS);
  m/
      %\ --BEGIN\ TEMPLATE--
      (.*)
      %\ --END\ TEMPLATE--
      /sx || die 'Unable to parse out the template';
  $template = '';
  $template .= "%!PS-Adobe-2.0 EPSF-2.0\n";
  $template .= "%%BoundingBox: 0 0 [% width %] [% height %]\n";
  $template .= "%%EndComments";
  $template .= $1;
  $template .= "2 2 scale\n";
  $template .= "10 7 moveto\n";
  $template .= "[% call %]\n";
  $template .= "showpage\n";
}

# Generates EAN13 barcode
sub generateBarcode {
  my ($name, $ean13, $prefix, $suffix, $width, $height, $directory) = @_;
  chomp($name);
  chomp($ean13);
  $ean13 =~ s/^\s*(.*?)\s*$/$1/; #trims whitespace
  $name =~ s/[^\w]/_/g; #replaces all characters except letters with underscore
  my $filename = lc("$prefix$name$suffix.$fileFormat");
  my $contents = "($ean13) (includetext guardwhitespace) /ean13 /uk.co.terryburton.bwipp findresource exec";
  my $barcode = $template;
  $barcode =~ s/\[% call %\]/$contents/;
  $barcode =~ s/\[% width %\]/$width/;
  $barcode =~ s/\[% height %\]/$height/;
  open(OUT,">", "$directory/$filename");
  print OUT $barcode;
  close(OUT);
}

# Clears the screen
sub clearScreen {
  print "\033[2J";
  print "\033[0;0H";
}

# Validates provided EAN13
# http://www.hashbangcode.com/blog/validate-ean13-barcodes
sub validateEan13 {
    my ($ean13) = @_;
    my $originalCheck = 0;
    if (length($ean13) == 13) {
      $originalCheck = substr($ean13, -1);
      $ean13 = substr($ean13, 0, -1);
    } elsif (length($ean13) != 12) {
      # Invalid EAN13 barcode
      return 0;
    }

    # Add even numbers together
    my $even = substr($ean13, 1, 1) + substr($ean13, 3, 1) + substr($ean13, 5, 1) + substr($ean13, 7, 1) + substr($ean13, 9, 1) + substr($ean13, 11, 1);
    # Multiply this result by 3
    $even = $even * 3;

    # Add odd numbers together
    my $odd = substr($ean13, 0, 1) + substr($ean13, 2, 1) + substr($ean13, 4, 1) + substr($ean13, 6, 1) + substr($ean13, 8, 1) + substr($ean13, 10, 1);

    # Add two totals together
    my $total = $even + $odd;

    # Calculate the checksum
    # Divide total by 10 and store the remainder
    my $checksum = $total % 10;
    # If result is not 0 then take away 10
    if ($checksum != 0) {
      $checksum = 10 - $checksum;
    }

    if ($originalCheck == $checksum) {
      return 1;
    } else {
      return 0;
    }
}

# Main function
sub init {
  clearScreen();
  print "EAN13 Barcode Generator\n";
  print "==============================================\n";
  print "Options:\n";
  print "[1] Manual entry\n[2] Batch generate from input.csv\n[0] Exit\n";
  print "Please choose your option [1,2,0]:";
  my $option = <>;

  if ($option == 1) {
    clearScreen();

    print "EAN13 Barcode Generator\n";
    print "==============================================\n";
    print "Manual entry\n";
    print "\n";
    print "Enter filename:";

    chomp(my $name = <>);

    my $ean13;
    my $ean13Check = 0;

    # Validates EAN13, if invalid ask to re-enter
    do {
      print "Enter EAN13 number:";
      chomp($ean13 = <>);

      $ean13Check = validateEan13($ean13);
      if (!$ean13Check) {
        print "$ean13 is an invalid EAN13, please try again.\n";
      }
    } while (!$ean13Check);

    generateBarcode($name , $ean13, $prefix, $suffix, $width, $height, $directory);

    my $filename = lc("$prefix$name$suffix.$fileFormat");

    print "\n";
    print "Results:\n";
    print "Operation complete.\n";
    print "$ean13($filename) barcode successfully generated to ./$directory directory.\n";
    print "\n";

    print "Press <enter> or <return> to continue:";
    my $response = <>;
    init();
  } elsif ($option == 2) {
    clearScreen();
    open(IN,"input.csv");
    my @items=<IN>;
    close(IN);

    my $successCount = 0;
    my $errorCount = 0;

    print "EAN13 Barcode Generator\n";
    print "==============================================\n";
    print "Batch generating EAN13 barcodes from input.csv\n";
    print "\n";
    print "Log:\n";

    foreach $_ (@items) {
      m/^(.*),(.*),(.*)$/ || m/^(.*),(.*)$/ ||  die "Bad line: $_";

      my $ean13Check = validateEan13($2);

      if (!$ean13Check) {
        print "$2($1) is invalid, please check EAN13.\n";
        $errorCount ++;
      } else {
        generateBarcode($1, $2, $prefix, $suffix, $width, $height, $directory);
        $successCount ++;
      }
    }

    print "\n";
    print "Results:\n";
    print "Operation complete";

    if ($errorCount > 0) {
      print " with $errorCount error(s), please see logs above.\n";
    } else {
      print ".\n";
    }

    print "$successCount barcodes successfully generated to ./$directory directory.\n";
    print "\n";

    print "Press <enter> or <return> to continue:";
    my $response = <>;
    init();
  } else {
    clearScreen();
    print "EAN13 Barcode Generator\n";
    print "==============================================\n";
    print "\n";
    print "Exit\n";
    print "\n";
    exit 42;
  }
}

initTemplate();
init();
