#!/usr/bin/perl
package TWatchGtk;

use strict;
use warnings;
use utf8;
use lib qw(../../lib ../lib);

use Glib qw(:constants);
use Gtk2;
#use Gtk2::Ex::Simple::List;

use TWatchGtk::Config;
use TWatchGtk::Controller;
use TWatch;

=head2 new

Конструктор приложения

=cut
sub new
{
    my ($class, %opts) = @_;

    # Загрузим Glade
    my $builder = Gtk2::Builder->new;
    $builder->add_from_file( config->get('Glade') );
    # Загрузим проекты
    my $twatch = TWatch->new or die "Can`t create Twatch object.";

    my $self = bless {app => $builder, twatch => $twatch} ,$class;

    $self->load_project_tree;

    # Подсоединим сигналы
    my $controller = TWatchGtk::Controller->new( $self->{app} );
    $self->{app}->connect_signals (undef, $controller);

    return $self;
}

# Стандартные функции ##########################################################

# Логика #######################################################################
=head2 load_project_tree

Загрузка описаний проекта

=cut
sub load_project_tree
{
    my ($self) = @_;

    # Получим объекты для работы
    my $tree    = $self->{app}->get_object('treeview_projects');
    my $twatch  = $self->{twatch};


}
1;