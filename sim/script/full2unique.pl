#!/usr/bin/perl
#*** OPTION ********************************************************************
    #use 5.010;
    use strict;
    use POSIX;


#*** VARIABLES *****************************************************************
    my $SRC = $ARGV[0];
    my $DST = $ARGV[1];
    my $TYP = $ARGV[2];
    my %strInc;
    my %strRtl;


#*** SUB FUNCTION **************************************************************
#--- GET INCLUDE -----------------------
    sub getInc {
        # log
        my $fptOut = $_[0];
        my $strInp = $_[1];

        # main loop
        open my $fptInp, "<$strInp";
        while (<$fptInp>) {
            chomp;
            s#\$PRJ_DIR#$ENV{PRJ_DIR}#;
            # include
            if (/\+incdir\+\s*(.*)/) {
                if (!exists($strInc{$1})) {
                    print $fptOut "+incdir+$1\n";
                    $strInc{$1} = 1;
                }
            }
            # -f
            elsif (/^\s*-f\s*(.*)$/) {
                getInc($fptOut, $1);
            }
        }
        close $fptInp;
    }


#--- GET LEFT --------------------------
    sub getLft {
        # log
        my $fptOut = $_[0];
        my $strInp = $_[1];
        print "processing $strInp\n";

        # main loop
        open my $fptInp, "<$strInp";
        while (<$fptInp>) {
            chomp;
            s#\$PRJ_DIR#$ENV{PRJ_DIR}#;
            # comments
            if (/^\s*\/\//) {
            }
            # -f
            elsif (/^\s*-f\s*(.*)$/) {
                getLft($fptOut, $1);
            }
            # include
            elsif (/incdir/) {
            }
            # blank line
            elsif (/^\s*$/) {
            }
            # design file
            else {
                $_ =~ /^\s*(\S*)\s*/;
                if (!exists($strRtl{$1})) {
                    print $fptOut "$1\n";
                    $strRtl{$1} = 1;
                }
            }
        }
        close $fptInp;
    }


#*** MAIN BODY *****************************************************************
#--- INCLUDE ---------------------------
    if ($TYP eq "INC") {
        # log begin
        open my $fptOut, ">$DST";
        print $fptOut "\n";

        # main loop
        getInc($fptOut, $SRC);

        # log end
        close $fptOut;
    }


#--- LEFT ------------------------------
    if ($TYP eq "LFT") {
        # log begin
        open my $fptOut, ">$DST";
        print $fptOut "\n";

        # main loop
        getLft($fptOut, $SRC);

        # log end
        close $fptOut;
    }
