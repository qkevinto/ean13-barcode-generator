# EAN13 Barcode Generator

## Summary

Generate barcodes as vector `.eps` files in pure postscript from either a `.csv` or manual entry.

## Features

* Uses Terry Burton's [Barcode Writer in Pure PostScript](https://github.com/bwipp/postscriptbarcode) library to generate barcodes.
* Built-in EAN13 validation using check digit, ported from [http://www.hashbangcode.com/blog/validate-ean13-barcodes](http://www.hashbangcode.com/blog/validate-ean13-barcodes).
* Single or batch operation with `.csv`.

## Usage

* Run `perl gen.pl`, `run.sh`, or `run.command` (on OSX) to get started and follow the prompts.
* For batch operation, ensure `input.csv` file present and is formatted as `filename,EAN13` per barcode, per line, ensuring that it is saved with Unix line feed `\n` rather than carriage return `\r` which could happen if you're exporting from Excel, refer to [http://nicercode.github.io/blog/2013-04-30-excel-and-line-endings](http://nicercode.github.io/blog/2013-04-30-excel-and-line-endings/).
