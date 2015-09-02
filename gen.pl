#!/usr/bin/perl -w

use strict;
use warnings;

my $template;
my $prefix = "";
my $suffix = "_barcode";
my $directory = "barcodes";
my $fileFormat = "eps";

# Get the barcode type attributes
sub getTypeAttributes {
    my ($type) = @_;
    my %attributes;

    if ($type eq "ean13") {
        $attributes{"width"} = "232";
        $attributes{"height"} = "153";
        $attributes{"scaleX"} = "2";
        $attributes{"scaleY"} = "2";
        $attributes{"movetoX"} = "10";
        $attributes{"movetoY"} = "7";
    } elsif ($type eq "itf14") {
        $attributes{"width"} = "342";
        $attributes{"height"} = "102";
        $attributes{"scaleX"} = "2";
        $attributes{"scaleY"} = "2";
        $attributes{"movetoX"} = "18";
        $attributes{"movetoY"} = "11";
    } else {
        %attributes;
    }

    return %attributes;
}

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
    $template .= "[% scaleX %] [% scaleY %] scale\n";
    $template .= "[% movetoX %] [% movetoY %] moveto\n";
    $template .= "[% call %]\n";
    $template .= "showpage\n";
}

# Generates barcode
sub generateBarcode {
    my ($name, $data, $type , $prefix, $suffix, $width, $height, $scaleX , $scaleY, $movetoX, $movetoY, $directory) = @_;
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
    $barcode =~ s/\[% scaleX %\]/$scaleX/;
    $barcode =~ s/\[% scaleY %\]/$scaleY/;
    $barcode =~ s/\[% movetoX %\]/$movetoX/;
    $barcode =~ s/\[% movetoY %\]/$movetoY/;
    open(OUT,">", "$directory/$filename");
    print OUT $barcode;
    close(OUT);
}

# Clears the screen
sub clearScreen {
    print "\033[2J";
    print "\033[0;0H";
}

sub validate {
    my ($type, $data) = @_;

    # Validates provided EAN13
    # http://www.hashbangcode.com/blog/validate-ean13-barcodes
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
        my $name;
        my $data;
        my $type;
        my %attributes;
        my $validation;
        my $filename;
        my $response;

        clearScreen();

        print "Barcode Generator\n";
        print "==============================================\n";
        print "Manual entry\n";
        print "\n";
        print "Enter filename:";

        chomp($name = <>);

        do {
            print "Enter barcode type [ean13, itf14]:";
            chomp($type = <>);

            %attributes = getTypeAttributes($type);

            if (!%attributes) {
                print "$type is an invalid, please try again.\n";
            }
        } while (!%attributes);

        $validation = 0;

        # Validates data, if invalid ask to re-enter
        do {
            print "Enter barcode data:";
            chomp($data = <>);

            $validation = validate($type, $data);

            if (!$validation) {
                print "$data is an invalid $type data, please try again.\n";
            }
        } while (!$validation);

        generateBarcode($name , $data, $type , $prefix, $suffix, $attributes{"width"}, $attributes{"height"}, $attributes{"scaleX"} , $attributes{"scaleY"}, $attributes{"movetoX"}, $attributes{"movetoY"}, $directory);

        $filename = lc("$prefix$name$suffix.$fileFormat");

        print "\n";
        print "Results:\n";
        print "Operation complete.\n";
        print "$data($filename) barcode successfully generated to ./$directory directory.\n";
        print "\n";

        print "Press <enter> or <return> to continue:";
        $response = <>;
        init();
    } elsif ($option == 2) {
        my $type;
        my %attributes;
        my $validation;
        my $filename;
        my $response;
        my $successCount = 0;
        my $errorCount = 0;
        my @items;

        clearScreen();
        open(IN,'<:raw:eol(LF)',"input.csv");
        @items = <IN>;
        close(IN);

        print "Barcode Generator\n";
        print "==============================================\n";

        do {
            print "Enter barcode type [ean13, itf14]:";
            chomp($type = <>);

            %attributes = getTypeAttributes($type);

            if (!%attributes) {
                print "$type is an invalid, please try again.\n";
            }
        } while (!%attributes);

        print "Batch generating barcodes from input.csv\n";
        print "\n";
        print "Log:\n";

        foreach $_ (@items) {
            m/^(.*),(.*),(.*)$/ || m/^(.*),(.*)$/ ||  die "Bad line: $_";

            $validation = validate($type, $2);

            if (!$validation) {
                print "$2($1) is invalid, please check $type data.\n";
                $errorCount ++;
            } else {
                generateBarcode($1 , $2, $type , $prefix, $suffix, $attributes{"width"}, $attributes{"height"}, $attributes{"scaleX"} , $attributes{"scaleY"}, $attributes{"movetoX"}, $attributes{"movetoY"}, $directory);
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
        $response = <>;
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
