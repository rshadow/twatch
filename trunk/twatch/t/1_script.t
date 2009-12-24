#!/usr/bin/perl

=head1 1_script.t

Тест скрипта запуска

=cut

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 1;
use Encode qw(decode);

################################################################################
# Тест подключений
################################################################################

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    diag("************* Test twatch *************");
}

################################################################################
# Тесты
################################################################################

sub t_compile
{
    `perl -c twatch &> /dev/null`;
    exec 'perl -c twatch' if $?;

    return 1;
}

###############################################################################
# Исполнение
################################################################################
ok(t_compile,    'Compilation test');