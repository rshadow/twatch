#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;
use Encode qw(decode);

################################################################################
# Use tests
################################################################################

BEGIN {
    # Prepare for utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    diag("************* Test Project *************");
    use_ok('TWatch');
    use_ok('TWatch::Project');
}

################################################################################
# Tests
################################################################################

sub t_1
{
    return 1;
}

###############################################################################
# Make
################################################################################
ok(t_1,    '');
