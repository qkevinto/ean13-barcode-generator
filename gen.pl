#!/usr/bin/perl -w

use strict;

my $template;
my $prefix = "";
my $suffix = "_barcode";
my $width = "232";
my $height = "153";
my $directory = "barcodes";

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
  chomp(my $name = $name);
  chomp(my $ean13 = $ean13);
  $ean13 =~ s/^\s*(.*?)\s*$/$1/; #trims whitespace
  $name =~ s/[^\w]/_/g; #replaces all characters except letters with underscore
  my $prefix = $prefix;
  my $suffix = $suffix;
  my $fileformat = "eps";
  my $filename = lc("$prefix$name$suffix.$fileformat");
  my $width = $width;
  my $height = $height;
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
    my $ean13 = $ean13;
    my $originalcheck = 0;
    if (length($ean13) == 13) {
      $originalcheck = substr($ean13, -1);
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

    if ($originalcheck == $checksum) {
      return 1;
    } else {
      return 0;
    }
}

# Main function
sub init {
  initTemplate();
  clearScreen();
  print "EAN13 Barcode Generator\n";
  print "[1] Manually enter EAN13\n[2] Batch generate EAN13 barcodes from input.csv\n[0] Exit\n";
  print "Please choose your option [1,2,0]:";
  my $option = <>;

  if ($option == 1) {
    clearScreen();
    print "EAN13 Barcode Generator\n";
    print "Manually enter EAN13\n";
    print "Enter filename:";
    chomp(my $name = <>);

    my $ean13;
    my $ean13check = 0;

    # Validates EAN13, if invalid ask to re-enter
    do {
      print "Enter EAN13 number:";
      chomp($ean13 = <>);

      $ean13check = validateEan13($ean13);
      if (!$ean13check) {
        print "$ean13 is invalid, please try again.\n";
      }
    } while (!$ean13check);

    generateBarcode($name , $ean13, $prefix, $suffix, $width, $height, $directory);

  } elsif ($option == 2) {
    clearScreen();
    print "EAN13 Barcode Generator\n";
    print "Batch generate EAN13 barcodes from input.csv\n";
    open(IN,"input.csv");
    my @items=<IN>;
    close(IN);

    foreach $_ (@items) {
      m/^(.*),(.*),(.*)$/ || m/^(.*),(.*)$/ ||  die "Bad line: $_";

      my $ean13check = validateEan13($2);

      if (!$ean13check) {
        print "$2($1) is invalid, please check EAN13.\n";
      } else {
        generateBarcode($1, $2, $prefix, $suffix, $width, $height, $directory);
      }
    }
    print "Complete\n";
  } elsif ($option == 0 || $option == "") {
    clearScreen();
    print "EAN13 Barcode Generator\n";
    print "Exit\n";
    exit 42;
  }
}

init();
