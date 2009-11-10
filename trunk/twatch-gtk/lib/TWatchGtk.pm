#!/usr/bin/perl
package TWatchGtk;

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;
#use Gtk2::Ex::Simple::List;

use TWatchGtk::Config;
use TWatch;
use TWatchGtk::Controller::About;

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

    # Получим объекты
    $self->{dlg}{main}{obj}     = $builder->get_object ('main');
    $self->{dlg}{about}{obj}    = $builder->get_object ('about');
    $self->{dlg}{settings}{obj} = $builder->get_object ('settings');

    # Подсоединим к объектам  сигналы из одноименных модулей
    for my $name (keys %{$self->{dlg}})
    {
        my $module = sprintf 'TWatchGtk::Controller::%s', ucfirst $name;
        eval "require $module";
        next if $@;
        $self->{dlg}{$name}{ctrl} = $module->new(
            app => $self->{app},
            obj => $self->{dlg}{$name}{obj}
        );
        $self->{app}->connect_signals (undef, $self->{dlg}{$name}{ctrl} );
    }

#    DieDumper $self->{dlg};


    $self->load_project_tree;

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