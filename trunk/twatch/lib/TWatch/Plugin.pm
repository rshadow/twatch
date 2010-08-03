package TWatch::Plugin;

=head1 NAME

TWatch::Plugin - Load and execute plugins

=cut

use strict;
use warnings;
use utf8;

use File::Basename qw(dirname);
use File::Path qw(make_path);

use base qw(Exporter);
our @EXPORT=qw(config DieDumper Dumper);

use TWatch::Config;

=head1 CONSTRUCTOR

=cut

=head2 new

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;
    return $self;
}

=head2 post

Execute post plugins.

=cut

sub post
{
    my ($self, $twatch) = @_;

    my @modules = glob(config->get('Plugin'));
    for my $module ( @modules )
    {
        # Get plugin module name
        s/^.*\/(.*?)\.pm$/$1/, s/^(.*)$/TWatch::Plugin::$1/ for $module;

        # Load plugin
        eval "require $module";
        printf("Can`t load plugin \"%s\": %s\n", $module, $@), next if $@;

        # Crape plugin object and set current cinfig
        my $plugin = eval{ $module->new( config ) };
        printf("Can`t create plugin \"%s\": %s\n", $module, $@), next
            if $@ or !$plugin;

        # Execute plugin with TWatch object
        eval{ $plugin->run( $twatch ) };
        printf("Can`t run plugin \"%s\": %s\n", $module, $@), next if $@;
    }
}

1;

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
