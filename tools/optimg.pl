#!/usr/bin/perl -w

#
# Optimize various types of images.
#

use strict;
use File::Basename;
use File::Copy;

my $pngout = "pngout.exe";              # see http://advsys.net/ken/util/pngout.htm 
my $optipng = "optipng.exe";            # also https://pngquant.org/ and http://optipng.sourceforge.net/

my $jpegoptim = "jpegoptim.exe";        # see http://freshmeat.net/projects/jpegoptim/; http://pornel.net/jpegoptim
my $jpegtran = "jpegtran.exe";          # http://www.kokkonen.net/tjko/projects.html https://github.com/mozilla/mozjpeg

my $gifsicle = "gifsicle.exe";          # see http://www.lcdf.org/gifsicle/
my $temp = "C:\\Temp";

my $errorCount = 0;
my $totalOriginalSize = 0;
my $totalResultSize = 0;
my $imagesConverted = 0;


sub list_recursively($);


sub list_recursively($) {
    my ($directory) = @_;
    my @files = (  );

    unless (opendir(DIRECTORY, $directory)) {
        print "Cannot open directory $directory!\n";
        exit;
    }

    # Read the directory, ignoring special entries "." and ".."
    @files = grep (!/^\.\.?$/, readdir(DIRECTORY));

    closedir(DIRECTORY);

    foreach my $file (@files) {
        if (-f "$directory\\$file") {
            handle_file("$directory\\$file");
        } elsif (-d "$directory\\$file") {
            list_recursively("$directory\\$file");
        }
    }
}


sub handle_file($) {
    my ($file) = @_;

    if ($file =~ m/^(.*)\.(png|jpg|jpeg|gif)$/) {
        my $path = $1;
        my $extension = $2;
        my $base = basename($file, '.' . $extension);
        my $dirname = dirname($file);

        my $newfile = $dirname . '\\' . $base . '-optimized.' . $extension;

        print "----- Optimizing image: $file\n";
        my $originalSize = -s $file;

        if ($extension eq 'png') {
            # my $returnCode = system ("$pngout /y \"$file\" \"$file\"");
            my $returnCode = system ("$optipng -o5 -strip all \"$file\" 2>>\&1");
        } elsif ($extension eq 'jpg' or $extension eq 'jpeg') {
            # my $returnCode = system ("$jpegoptim --strip-all \"$file\"");
            my $returnCode = system ("$jpegtran -copy none \"$file\" 1>>\"$newfile\"");
            move($newfile, $file);
        } elsif ($extension eq 'gif') {
            my $returnCode = system ("$gifsicle -O2 --batch \"$file\"");
        }

        my $resultSize = -s $file;

        $imagesConverted++;
        $totalOriginalSize += $originalSize;
        $totalResultSize += $resultSize;
    }
}


sub main() {
    ## initial call ... $ARGV[0] is the first command line argument
    list_recursively($ARGV[0]);

    print "Number of images:          $imagesConverted\n";
    if ($errorCount > 0) {
        print "Number of errors:          $errorCount\n";
    }
    if ($imagesConverted > 0) {
        print "Original size of images:   $totalOriginalSize bytes\n";
        print "New size of images:        $totalResultSize bytes\n";
        print "Space saved:               " . ($totalOriginalSize - $totalResultSize) . " bytes\n";
    }
}


main();
