package TWatch::Config;

=head1 NAME

TWatch::Config - Load project configuretion

=cut

use strict;
use warnings;
use utf8;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use POSIX qw(strftime);

use base qw(Exporter);
our @EXPORT=qw(config notify DieDumper Dumper);

###############################################################################
# This section contains some paths for use in this program
# Edit this for some OS
# I think no any place to change. If it`s wrong, please inform me.
# (Except config file)
################################################################################
use constant TWATCH_SYSTEM_CONFIG_PATH  => '/etc/twatch/twatch.conf';
use constant TWATCH_CONFIG_PATH         => '~/.twatch/twatch.conf';
use constant TWATCH_LOG_PATH            => '~/.twatch/twatch.log';
###############################################################################

# Colors for highlight console output
use constant COLOR_RED      => "\e[1;31m";
use constant COLOR_GREEN    => "\e[1;32m";
use constant COLOR_YELLOW   => "\e[1;33m";
use constant COLOR_CLEAR    => "\e[0m";

=head1 CONSTRUCTOR

=cut

=head2 config

Load and cache configuratuon.
Use this funtction for access configuration params.

=cut

sub config
{
    our $config;
    return $config if $config;

    $config = TWatch::Config->new;
    return $config;
}

=head2 new

Load and return configuration object

=cut

sub new
{
    my ($class, %opts) = @_;
    my %config = (dir => {}, param => {});

    # Версии конфигов
    $config{dir}{config} = [
        TWATCH_SYSTEM_CONFIG_PATH,
        TWATCH_CONFIG_PATH,
    ];

    my $self = bless \%config ,$class;

    # Load config
    $self->load;

    # Check configuration
#    $self->check;

    # Create dirs (if not exists)
    $self->create_dir;

    # Open log file and print data
    my $path = TWATCH_LOG_PATH;
    $path =~ s/^~/$ENV{HOME}/;# glob $path;
    $self->set('Log', $path);
    open my $h, '+>>:encoding(UTF-8)', $path or die 'Can`t open log file: '.$!;
    printf $h "*** %s ***\n",
        POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
    $self->set('hLog', $h);

    return $self;
}

sub DESTROY
{
    my ($self) = @_;

    # Close log file
    if( $self->get('hLog') )
    {
        close $self->get('hLog')
            or die 'Can`t close log file: '.$!;
    }
}

################################################################################

=head1 METHODS

=cut

=head2 load

Load current config

=cut

sub load
{
    my ($self) = @_;

    # Flag successful loaded
    my $loaded = 'no';

    # Loading: first default config, next over users config
    for my $config ( @{$self->{dir}{config}} )
    {
        # Get abcoulete path
        ($config) = glob $config;

        # Next if file not exists
        next unless -f $config;

        # Open config file
        open my $file, '<', $config
            or warn sprintf('Can`t read config file %s : %s', $config, $!);
        next unless $file;

        # Read and parse file. Next hash write over previus configuration hash
        %{ $self->{param} } = (
            %{ $self->{param} },
            (
                map{ split m/\s*=\s*/, $_, 2 }
                grep m/=/,
                map { s/#\s.*//; s/^\s*#.*//; s/\s+$//; s/^\s+//; $_ } <$file>
            )
        );

        # Close file and mark successful loaded
        close $file;
        $loaded = 'yes';
    }

    # Exit if no one config exists
    die 'Config file not exists' unless $loaded eq 'yes';

    # Save original because it can be edit by user (twatch-gtk)
    %{ $self->{orig} } = %{ $self->{param} };

    # Transform some parameters for comfort usage
    $self->{param}{EmailLevel} = [ split ',', $self->{param}{EmailLevel} ];
    s/^\s*//, s/\s*$// for @{ $self->{param}{EmailLevel} };

    $self->{param}{NoProxy} =
        ($self->{param}{NoProxy} =~ m/^(1|yes|true|on)$/i) ?1 :0;

    return 1;
}

=head2 get $name

Get parameter by $name.

=cut

sub get
{
    my ($self, $name) = @_;
    return $self->{param}{$name};
}

=head2 get_orig $name

Get original (as in config file) parameter by $name.

=cut

sub get_orig
{
    my ($self, $name) = @_;
    return $self->{orig}{$name};
}

=head2 set $name, $value

Set new $value for parameter by $name.

=cut

sub set
{
    my ($self, $name, $value) = @_;
    $self->{param}{$name} = $value;
}

################################################################################

=head1 NOTIFICATIONS METHODS

=cut

=head2 notify $message, $level,  $wait

Send $message to standart output.
Param $level ( good|warn|bad ) highlight the message.
The $wait indicate print or not \n in the end of message.

=cut

sub notify
{
    my ($message, $level, $wait) = @_;

    # Skip unless message
    return unless $message;

    # Format message by module
    $message = ((' ') x 2) . $message if caller eq 'TWatch';
    $message = ((' ') x 4) . $message if caller eq 'TWatch::Project';
    $message = ((' ') x 6) . $message if caller eq 'TWatch::Watch';

    # Unless waiting flag print \n
    $message .= "\n" unless $wait;

    # Print to log file
    my $h = config->get('hLog');
    print $h $message;

    # Skip if output disabled
    return unless config->get('verbose');

    # Highlight message
    $level = lc $level || '';
    if( $level eq 'good' )
        { $message = COLOR_GREEN    . $message . COLOR_CLEAR  }
    elsif( $level eq 'warn' )
        { $message = COLOR_YELLOW   . $message . COLOR_CLEAR  }
    elsif( $level eq 'bad' )
        { $message = COLOR_RED      . $message . COLOR_CLEAR  }

    print $message;
}

################################################################################

=head1 MORE FUNCTIONS

=cut

=head2 create_dir

Create directories in user home path if it is not exists.

=cut

sub create_dir
{
    my ($self) = @_;

    # Create list of directories
    for my $param ('Save', 'Project', 'Complete')
    {
        # Get path
        my $path = $self->get($param);
        # Get absoulete path
        $path =~ s/^~/$ENV{HOME}/;# glob $path;
        # Set new absoulete path in configuration
        $self->set($param, $path);

        # Get dirs from params (It can consist mask and etc.)
        # (Save is a directory)
        my $dir = $path;
        $dir = dirname( $dir ) unless $param eq 'Save';
        # Next if directory exists
        next if -d $dir;
        # Create one
        eval{ make_path $dir; };
        die sprintf("Can`t create store directory: %s, %s\n", $dir, $@) if $@;
    }
}

################################################################################

=head1 DEBUG METHODS

=cut

=head2 DieDumper

Print all params and die

=cut

sub DieDumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);
    # юникодные символы преобразуем в них самих
    # вметсто \x{уродство}
    $dump=~s/(\\x\{[\da-fA-F]+\})/eval "qq{$1}"/eg;
    die $dump;
}

=head2 Dumper

Get all params description

=cut

sub Dumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);

    return $dump;
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