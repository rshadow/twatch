package TWatch::Complete;

=head1 NAME

TWatch::Watch::CompleteList - Load and save completed tasks for watch

=cut

use strict;
use warnings;
use utf8;

use XML::Simple;

use TWatch::Config;
use TWatch::Watch::ResultList;

=head1 CONSTRUCTORS

=cut

=head2 new

Load completed tasks and return this object

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->load if $self->{cfile};

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

    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
        }
    );

    # Load completed tasks for project
    my $complete = $xs->XMLin( $self->{cfile} );

    # Fix XML in
    for my $name ( keys %{ $complete->{watches} } )
    {
        # Add empty array even watch empty
        $complete->{watches}{$name}{complete} = []
            unless %{ $complete->{watches}{$name} };

        # Convert empty hashes in empty strings
        for my $result ( @{ $complete->{watches}{$name}{complete} } )
        {
            for my $key ( keys %$result)
            {
                $result->{$key} = ''
                    if 'HASH' eq ref $result->{$key} and !%{$result->{$key}};
            }
        }

        my $results = TWatch::Watch::ResultList->new;
        $results->add( $complete->{watches}{$name}{complete} );
        # Convert hash to result list object
        $complete->{watches}{$name} = $results;
    }

    # Set data to object
    $self->{$_} = $complete->{$_} for keys %$complete;

    return $self;
}

=head2 param $name, $value

If defined $value set param $name value. Unless return it`s value.

=cut

sub param
{
    my ($self, $name, $value) = @_;
    die 'Undefined param name'  unless $name;
    die 'Use public methods'    if $name eq 'watches';

    $self->{$name} = $value if defined $value;
    return $self->{$name};
}

=head2 get

Get completed tasks for $name watch

=cut

sub get
{
    my ($self, $name) = @_;

    # If completed not exists then create new one empty.
    $self->{watches}{$name} =
        TWatch::Watch::ResultList->new( name => $name, complete => [] )
            unless exists $self->{watches}{$name};

    return $self->{watches}{$name};
}

=head2 save

Save list completed tasks

=cut

sub save
{
    my ($self, $project) = @_;

    # Get watches names
    my %watches = $project->watches;

    for my $name ( keys %watches )
    {
        my %result = $watches{$name}->complete->get;
        $watches{$name} = {
            name        => $name,
            ($watches{$name}->complete->count)
                ?(complete => { result => [values %result] })
                :(),
        }
    };

    # Make data to save
    my $save = {
        name    => $project->param('name'),
        update  => $project->param('update'),
        watches => { watch => [ values %watches ] },
    };

    # Get file name to save
    my $file = $project->param('cfile');
    # Full path consists of completed path and project filename if it is
    # new file
    $file = (config->get('Complete') =~ m/^(.*)\/.*?$/)[0] .
            ($project->param('file') =~ m/^.*(\/.*?\.xml)$/)[0]
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