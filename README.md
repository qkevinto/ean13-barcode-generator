# PostScript Barcode Generator

## Note

This is the first Perl thing I've ever written, and done so rather quickly to have the tool at a usable state, so if there is anything weird let me know or feel free to PR a fix!

## Requirements

* [PerlIO::eol](http://search.cpan.org/~audreyt/PerlIO-eol-0.14/eol.pm) for normalizing line endings, though this seems to be included with Perl already.

## Summary

Generate barcodes as vector `.eps` files in pure postscript from either a `.csv` or manual entry.

## Features

* Uses Terry Burton's [Barcode Writer in Pure PostScript](https://github.com/bwipp/postscriptbarcode) library to generate barcodes.
* Built-in EAN13 validation using check digit, ported from [http://www.hashbangcode.com/blog/validate-ean13-barcodes](http://www.hashbangcode.com/blog/validate-ean13-barcodes).
* Single or batch operation with `.csv`.

## Usage

* Run `perl gen.pl`, `run.sh`, or `run.command` (on OSX) to get started and follow the prompts.
* For batch operation, ensure `input.csv` file is present and formatted as `filename,data` per barcode, per line.
