package TWatch::Plugin::Example;

=head1 TWatch::Plugin::Example

Пример плагина постобработки

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../../lib);

use TWatch::Config;

sub new
{
    my ($class, $config) = @_;
    return bless {string => 'Example plugin successfully attached.'}, $class;
}

sub run
{
    my ($self, $twatch) = @_;
    printf "%s\n", $self->{string};
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut

1;