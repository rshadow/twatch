#!/usr/bin/perl

=head1 1_script.t

Compilation test

=cut

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 1;
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

    diag("************* Test twatch *************");
}

################################################################################
# Tests
################################################################################

sub t_compile
{
    `perl -c twatch &> /dev/null`;
    exec 'perl -c twatch' if $?;

    return 1;
}

###############################################################################
# Make
################################################################################
ok(t_compile,    'Compilation test');