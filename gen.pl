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

# Generates barcode
sub generateBarcode {
  my ($name, $data, $type , $prefix, $suffix, $width, $height, $directory) = @_;
  chomp($name);
  chomp($data);
  $data =~ s/^\s*(.*?)\s*$/$1/; #trims whitespace
  $name =~ s/[^\w]/_/g; #replaces all characters except letters with underscore
  my $filename = lc("$prefix$name$suffix.$fileFormat");
  my $contents = "($data) (includetext guardwhitespace) /$type /uk.co.terryburton.bwipp findresource exec";
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
sub validate {
    my ($type, $data) = @_;

    if ($type eq "ean13") {
        my $originalCheck = 0;
        if (length($data) == 13) {
          $originalCheck = substr($data, -1);
          $data = substr($data, 0, -1);
        } elsif (length($data) != 12) {
          # Invalid EAN13 barcode
          return 0;
        }

        # Add even numbers together
        my $even = substr($data, 1, 1) + substr($data, 3, 1) + substr($data, 5, 1) + substr($data, 7, 1) + substr($data, 9, 1) + substr($data, 11, 1);
        # Multiply this result by 3
        $even = $even * 3;

        # Add odd numbers together
        my $odd = substr($data, 0, 1) + substr($data, 2, 1) + substr($data, 4, 1) + substr($data, 6, 1) + substr($data, 8, 1) + substr($data, 10, 1);

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
    } else {
        return 1;
    }
}

# Main function
sub init {
  clearScreen();
  print "Barcode Generator\n";
  print "==============================================\n";
  print "Options:\n";
  print "[1] Manual entry\n[2] Batch generate from input.csv\n[0] Exit\n";
  print "Please choose your option [1,2,0]:";
  my $option = <>;

  if ($option == 1) {
    clearScreen();

    print "Barcode Generator\n";
    print "==============================================\n";
    print "Manual entry\n";
    print "\n";
    print "Enter filename:";

    chomp(my $name = <>);

    print "See supported barcode types here:";
    print "\n";
    print "https://github.com/bwipp/postscriptbarcode/wiki/Symbologies-Reference";
    print "\n";
    print "Enter barcode type:";

    chomp(my $type = <>);

    my $data;
    my $validation = 0;

    # Validates EAN13, if invalid ask to re-enter
    do {
      print "Enter barcode data:";
      chomp($data = <>);

      $validation = validate($type, $data);

      if (!$validation) {
          print "$data is an invalid $type data, please try again.\n";
      }
  } while (!$validation);

    generateBarcode($name , $data, $type , $prefix, $suffix, $width, $height, $directory);

    my $filename = lc("$prefix$name$suffix.$fileFormat");

    print "\n";
    print "Results:\n";
    print "Operation complete.\n";
    print "$data($filename) barcode successfully generated to ./$directory directory.\n";
    print "\n";

    print "Press <enter> or <return> to continue:";
    my $response = <>;
    init();
  } elsif ($option == 2) {
    clearScreen();
    open(IN,'<:raw:eol(LF)',"input.csv");
    my @items = <IN>;
    close(IN);

    my $successCount = 0;
    my $errorCount = 0;

    print "Barcode Generator\n";
    print "==============================================\n";
    print "See supported barcode types here:";
    print "\n";
    print "https://github.com/bwipp/postscriptbarcode/wiki/Symbologies-Reference";
    print "\n";
    print "Enter barcode type:";

    chomp(my $type = <>);

    print "Batch generating barcodes from input.csv\n";
    print "\n";
    print "Log:\n";

    foreach $_ (@items) {
      m/^(.*),(.*),(.*)$/ || m/^(.*),(.*)$/ ||  die "Bad line: $_";

      my $validation = validate($type, $2);

      if (!$validation) {
        print "$2($1) is invalid, please check $type data.\n";
        $errorCount ++;
      } else {
        generateBarcode($1, $2, $type, $prefix, $suffix, $width, $height, $directory);
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
    print "Barcode Generator\n";
    print "==============================================\n";
    print "\n";
    print "Exit\n";
    print "\n";
    exit 42;
  }
}

initTemplate();
init();
