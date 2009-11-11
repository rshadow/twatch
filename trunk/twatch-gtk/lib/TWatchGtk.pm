#!/usr/bin/perl
package TWatchGtk;

use strict;
use warnings;
use utf8;
use lib qw(..);

use TWatch;
use TWatchGtk::Config;
use TWatchGtk::Controller::Main;

=head2 new

Конструктор приложения

=cut
sub new
{
    my ($class, %opts) = @_;
    my $self = bless \%opts ,$class;

    # Загрузим проекты
    $self->{twatch} = TWatch->new or die "Can`t create Twatch object.";

    # Создадим главное окно
    $self->{main} = TWatchGtk::Controller::Main->new(twatch => $self->{twatch});
    # Первоначальная загрузка дерева проектов
    $self->{main}->build_project_tree;

    return $self;
}

1;