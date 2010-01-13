package TWatch::Complete;

=head1 NAME

TWatch::Complete - Load and save completed tasks

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use base qw(Exporter);
our @EXPORT=qw(complete);

use XML::Simple;

use TWatch::Config;

=head1 CONSTRUCTORS

=cut

=head2 complete

Load and cache completed tasks.
Use this funtction for access completed tasks.

=cut

sub complete
{
    our $complete;

    $complete = TWatch::Complete->new() unless $complete;

    return $complete;
}

=head2 new

Load completed tasks and return this object

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->load;

    return $self;
}

=head1 METHODS

=cut

=head2 load

Load completed tasks

=cut

sub load
{
    my ($self) = @_;

    # Загрузим завершенные задания
    my @complete = glob(config->get('Complete'));
    return unless @complete;

    # Объект для работы с XML
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        }
    );

    # Загрузим все выполненные задания
    $_ = { %{$xs->XMLin($_)}, cfile => $_ } for @complete;

    # Очистим результаты от пустых хешей (Гнусный хак чистки за XML::Simple)
    for my $complete ( @complete )
    {
        for my $name ( keys %{ $complete->{watches} } )
        {
            # Добавим пустой массив выполненных, даже если их нету
            $complete->{watches}{$name}{complete} = []
                unless %{ $complete->{watches}{$name} };

            # В завершенных почистим пустые хеши
            for my $result ( @{ $complete->{watches}{$name}{complete} } )
            {
                for my $key ( keys %$result)
                {
                    $result->{$key} = ''
                        if 'HASH' eq ref $result->{$key} and !%{$result->{$key}};
                }
            }
        }
    }

    # Перестроим для быстрого доступа по имени проекта
    $self->{project} = {};
    $self->{project}{ $_->{name} } = $_ for @complete;
}

=head2 get

Get completed tasks for $name project

=cut

sub get
{
    my ($self, $name) = @_;

    return unless exists $self->{project}{$name};
    return $self->{project}{$name};
}

=head2 save

Save list completed tasks

=cut

sub save
{
    my ($self, $project) = @_;

    # Get project
    my $watches = $project->watches;

    for my $name ( keys %$watches )
    {
        $watches->{$name} = {
            name        => $name,
            ($watches->{$name}->complete_count)
                ?(complete => { result => [values %{ $watches->{$name}->complete }] })
                :(),
        }
    };

    # Make data to save
    my $save = {
        name    => $project->name,
        update  => $project->update,
        watches => { watch => [ values %$watches ] },
    };

    # Get file name to save
    my $file = $project->cfile;
    # Full path consists of completed path and project filename if it is
    # new file
    $file = (config->get('Complete') =~ m/^(.*)\/.*?$/)[0] .
            ($project->file =~ m/^.*(\/.*?\.xml)$/)[0]
        unless $file;

    # Save completed
    my $xs = XML::Simple->new(
        AttrIndent  => 1,
        KeepRoot    => 1,
        RootName    => 'project',
        NoAttr      => 1,
#        NoEscape    => 1,
        NoSort      => 1,
        ForceArray  => ['watch', 'result'],
        XMLDecl     => 1,
        OutputFile  => $file,
    );
    my $xml = $xs->XMLout($save);

    return 1;
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=head1 AUTHORS

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;