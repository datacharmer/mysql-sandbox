package MySQL::Sandbox;
use strict;
use warnings;
use Carp;
use English qw( -no_match_vars ); 
use Socket;
use File::Find;

use base qw( Exporter);
our @ISA= qw(Exporter);
our @EXPORT_OK= qw( is_port_open
                    is_a_sandbox
                    find_safe_port_and_directory
                    first_unused_port
                    get_sandbox_params 
                    is_sandbox_running
                    get_sb_info
                    get_ports
                    get_ranges
                    get_option_file_contents ) ;

our $VERSION='2.0.98d';
our $DEBUG;

BEGIN {
    $DEBUG = $ENV{'SBDEBUG'} || $ENV{'SBVERBOSE'} || 0;
    unless ( $ENV{SANDBOX_HOME} ) { 
        $ENV{SANDBOX_HOME} = "$ENV{HOME}/sandboxes";
    }

    if ( -d "$ENV{HOME}/sandboxes" ) {
        $ENV{SANDBOX_HOME} = $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";
    }
}

my @supported_versions = qw( 3.23 4.0 4.1 5.0 5.1 5.2 6.0);

our $sandbox_options_file    = "my.sandbox.cnf";
our $sandbox_current_options = "current_options.conf";

our %default_base_port = (
    replication => 11000,
    circular    => 14000,
    multiple    =>  7000,
    custom      =>  5000,
); 


sub new {
    my ($class) = @_;
    my $self = bless {
        parse_options => undef,
        options => undef,
    }, $class;
    # my $version = get_version( $install_dir);
    # $self->{version} = $VERSION;
    return $self;
}

sub parse_options {
    my ($self, $opt ) = @_;
    # print "<", ref($opt) , ">\n";
    unless (ref($opt) eq 'HASH') {
        confess "parse_options must be a hash reference\n";
    }
    if ($opt) {
        $self->{parse_options} = $opt;
    }
    my %options = map { $_ ,  $opt->{$_}{'value'}}  keys %{$opt};
    $self->{options} = \%options;

    return $self->{options};
}

sub find_safe_port_and_directory {
    my ($wanted_port, $wanted_dir, $upper_directory) = @_;
    my $chosen_port = $wanted_port;
    my ($ports, undef) = get_sb_info( $ENV{SANDBOX_HOME}, undef); 
    while ( is_port_open($chosen_port) or exists $ports->{$chosen_port}) {
        $chosen_port++;
        $chosen_port = first_unused_port($chosen_port);
        print "checking -> $chosen_port\n";
    }
    my $suffix = 'a';
    my $chosen_dir = $wanted_dir;
    while ( -d "$upper_directory/$chosen_dir" ) {
        print "checking -> $chosen_dir\n";
        $chosen_dir = $wanted_dir . '_' . $suffix;
        $suffix++;
    }
    return ($chosen_port, $chosen_dir);
}

sub get_help {
    my ($self, $msg) = @_;
    if ($msg) {
        warn "[***] $msg\n\n";
    }

    my $HELP_MSG = q{};
    for my $op ( 
                sort { $self->{parse_options}->{$a}{so} <=> $self->{parse_options}->{$b}{so} } 
                grep { $self->{parse_options}->{$_}{parse}}  keys %{ $self->{parse_options} } ) {
        my $param =  $self->{parse_options}->{$op}{parse};
        my $param_str = q{    };
        my ($short, $long ) = $param =~ / (?: (\w) \| )? (\S+) /x;
        if ($short) {
            $param_str .= q{-} . $short . q{ };
        } 
        $long =~ s/ = s \@? / = name/x;
        $long =~ s/ = i / = number/x;
        $param_str .= q{--} . $long;
        $param_str .= (q{ } x (40 - length($param_str)) );
        my $text_items = $self->{parse_options}->{$op}{help};
        for my $titem (@{$text_items}) {
            $HELP_MSG .= $param_str . $titem . "\n";
            $param_str = q{ } x 40;
        }
        if (@{$text_items} > 1) {
            $HELP_MSG .= "\n";
        }
        # $HELP_MSG .= "\n";
   }

   print $self->credits(),
          "syntax: $PROGRAM_NAME [options] \n", 
          $HELP_MSG, 
        "\nExample:\n",
        "     $PROGRAM_NAME --my_file=large --sandbox_directory=my_sandbox\n\n";

    exit(1);
}

sub credits {
    my ($self) = @_;
    my $CREDITS = 
          qq(    The MySQL Sandbox,  version $VERSION\n) 
        . qq(    (C) 2006,2007,2008 Giuseppe Maxia, Sun Microsystems, Database Group\n);
    return $CREDITS;
}

#sub get_version {
#    my ($install_dir) = @_;
#    open my $VER , q{<}, "$install_dir/VERSION"
#    #open my $VER , q{<}, "VERSION"
#        or die "file 'VERSION' not found\n";
#    my $version = <$VER>;
#    chomp $version;
#    close $VER;
#    return $version;
#}

sub write_to {
    my ($self, $fname, $mode, $contents) = @_;
    open my $FILE, $mode, $fname
        or die "can't open file $fname\n";
    print $FILE $contents, "\n";
    close $FILE;
}

sub supported_versions {
    return \@supported_versions;
}

sub is_port_open {
    my ($port) = @_;
    die "No port" unless $port;
    my ($host, $iaddr, $paddr, $proto);

    $host  =  '127.0.0.1';
    $iaddr   = inet_aton($host)               
        or die "no host: $host";
    $paddr   = sockaddr_in($port, $iaddr);

    $proto   = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto)
        or die "error creating test socket for port $port: $!";
    if (connect(SOCK, $paddr)) {
        close (SOCK)
            or die "error closing test socket: $!";
        return 1;
    }
    return 0; 
}

sub first_unused_port {
    my ($port) = @_;
    while (is_port_open($port)) {
        $port++;
        if ($port > 0xFFF0) {
            die "no ports available\n";
        }
    }
    return $port;
}

##
# SBtool
#
sub get_sandbox_params {
    my ($dir, $skip_strict) = @_;
    confess "directory name required\n" unless $dir;
    confess "directory $dir doesn't exist\n" unless -d $dir;
    unless (is_a_sandbox($dir)) {
        confess "directory <$dir> must be a sandbox\n" unless $skip_strict;
    }
    my %params = (
        opt  => undef,
        conf => undef
    );
    if ( -f "$dir/$sandbox_options_file" ) {
        $params{opt} = get_option_file_contents("$dir/$sandbox_options_file");
    }
    else {
        # warn "options file $dir not found\n";
        return;
    }
    if ( -f "$dir/$sandbox_current_options" ) {
        $params{conf} =
          get_option_file_contents("$dir/$sandbox_current_options");
    }
    else {
        # warn "current conf file not found\n";
        return;
    }
    return \%params;
}

sub get_option_file_contents {
    my ($file) = @_;
    confess "file name required\n" unless $file;
    confess "file $file doesn't exist\n" unless -f $file;
    my %options;
    open my $RFILE, q{<}, $file
      or confess "can't open file $file\n";
    while ( my $line = <$RFILE> ) {
        next if $line =~ /^\s*$/;
        next if $line =~ /^\s*#/;
        next if $line =~ /^\s*\[/;
        chomp $line;
        my ( $key, $val ) = split /\s*=\s*/, $line;
        $key =~ s/-/_/g;
        $options{$key} = $val;
    }
    close $RFILE;
    # print Dumper(\%options) ; exit;
    return \%options;
}

sub get_sb_info {
    my ($search_path, $options) = @_;
    my %ports         = ();
    my %all_info      = ();
    my $seen_dir      = '';

    find(
        {
            no_chdir => 1,
            wanted   => sub {
                if ( $seen_dir eq $File::Find::dir ) {
                    return;
                }
                my $params;
                if ( $params = get_sandbox_params($File::Find::dir, 1) ) {
                    $seen_dir = $File::Find::dir;
                    my $port = $params->{opt}{port};
                    if (   -f $params->{opt}{pid_file}
                        && -e $params->{opt}{socket} )
                    {
                        $ports{$port} = 1;
                        $all_info{$port} = $params if $options->{all_info};
                    }
                    else {
                        unless ( $options->{only_used} ) {
                            $ports{$port} = 0;
                            $all_info{$port} = $params if $options->{all_info};
                        }
                    }
                }
              }
        },
        $search_path || $options->{search_path}
    );
    return ( \%ports, \%all_info );
}

sub is_a_sandbox {
    my ($dir) = @_;
    unless ($dir) {
        confess "directory missing\n";
    }
    $dir =~ s{/$}{};
    my %sandbox_files = map {s{.*/}{}; $_, 1 } glob("$dir/*");
    my @required = (qw(data start stop send_kill clear use restart), 
         $sandbox_current_options, $sandbox_options_file );
    for my $req (@required) {
        unless (exists $sandbox_files{$req}) {
            return;
        }
    } 
    return 1;
}

sub is_sandbox_running {
    my ($sandbox) = @_;
    unless ( -d $sandbox ) {
        confess "Can't see if it's running. <$sandbox> is not a sandbox\n";
    }
    my $sboptions = get_sandbox_params($sandbox);
    unless ($sboptions->{opt} 
            && $sboptions->{opt}{'pid_file'} 
            && $sboptions->{opt}{'socket'}) {
        # print Dumper($sboptions);
        confess "<$sandbox> is not a single sandbox\n";
    }
    if (   ( -f $sboptions->{opt}{'pid_file'} )
        && ( -e $sboptions->{opt}{'socket'}) ) {
        return (1, $sboptions);
    }  
    else {
        return (0, $sboptions);
    }
}

sub get_ranges {
    my ($options) = @_;
    my ( $ports, $all_info ) = get_sb_info(undef, $options);
    my $minimum_port = $options->{min_range};
    my $maximum_port = $options->{max_range};
    my $range_size   = $options->{range_size};
    if ( $minimum_port >= $maximum_port ) {
        croak "minimum range must be lower than the maximum range\n";
    }
    if ( ( $minimum_port + $range_size ) > $maximum_port ) {
        croak "range too wide for given boundaries\n";
    }
    my $range_found = 0;
  range_search:
    while ( !$range_found ) {
        if ( $minimum_port >= $maximum_port ) {
            croak "can't find a range of $range_size "
              . "free ports between "
              . "$options->{min_range} and $options->{max_range}\n";
        }
        for my $i ( $minimum_port .. $minimum_port + $range_size ) {
            if ( exists $ports->{$i} or ( $i >= $maximum_port ) ) {
                $minimum_port = $i + 1;
                next range_search;
            }
        }
        $range_found = 1;
    }
    printf "%5d - %5d\n", $minimum_port , $minimum_port + $range_size;
}

sub get_ports {
    my ($options) = @_;
    my ( $ports, $all_info ) = get_sb_info(undef, $options);

    if ( $options->{format} eq 'perl' ) {
        print Data::Dumper->Dump( [$ports], ['ports'] );
        print Data::Dumper->Dump( [$all_info], ['all_info'] )
          if $options->{all_info};
    }
    elsif ( $options->{format} eq 'text' ) {
        for my $port ( sort { $a <=> $b } keys %$ports ) {
            printf "%5d %2d\n", $port, $ports->{$port};
        }
    }
    else {
        croak "unrecognized format -> $options->{format}\n";
    }
    return ( $ports, $all_info );
}

1;
__END__

=head1 NAME

MySQL::Sandbox - Quickly installs MySQL side server, either standalone or in groups

=head1 SYNOPSIS

 make_sandbox /path/to/MySQL-VERSION.tar.gz


=head1 PURPOSE

This package is a sandbox for testing features under any version of
MySQL from 3.23 to 6.0.

It will install one node under your home directory, and it will
provide some useful commands to start, use and stop this sandbox.

With this package you can play with new MySQL releases without need 
of using other computers. The server installed in the sandbox use 
non-standard data directory, ports and sockets, so they won't 
interfere with existing MYSQL installations.

=head1 INSTALLATION
MySQL Sandbox installs as a normal Perl Module. Since its purpose is to
install side servers in user space, you can install it as root (default) 
or as an unprivileged user. In this case, you need to set the PERL5LIB 
and PATH variables.


   # as root
   perl Makefile.PL 
   make
   make test
   make install

   # as normal user
   export PATH=$HOME/usr/local/bin:$PATH
   export PERL5LIB=$HOME/usr/local/lib/perl5/site_perl/5.8.8
   perl Makefile.PL PREFIX=$HOME/usr/local
   make
   make test
   make install

=head1 MAKING SANDBOXES

=head2 SINGLE SERVER SANDBOX

The easiest way to make a sandbox is 

=over 3

=item 1
download the sandbox package and install it as instructed above

=item 2
download a MySQL binary tarball

=item 3
run this command

   $ make_sandbox  /path/to/mysql-X.X.XX-osinfo.tar.gz

=back

That's all it takes to get started. The Sandbox will ask you for confirmation, and then it will tell you where it has installed your server. 

By default, the sandbox creates a new instance for you under

   $HOME/sandboxes/msb_X_X_XX


=head2 MAKING A REPLICATION SANDBOX

It's as easy as making a single sandbox

   $ make_replication_sandbox /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a new instance of one master  and two slaves

   under $HOME/sandboxes/rsandbox_X_X_XX

=head2 CIRCULAR REPLICATION

It requires an appropriate option when you start a replication sandbox

   $ make_replication_sandbox --circular=4 /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a replication system with three servers connected by circular replication.
A handy shortcut is C(--master_master), which will create a circular replication system of exactly two members.

=head2 MULTIPLE SANDBOXES

You can create a group of sandboxes without any replication among its members.
If you need three servers of the same version, you can use

 $ make_multiple_sandbox /path/to/tarball 
    
If you need servers of different versions in the same group, you may like

 $ make_multiple_custom_sandbox /path/to/tarball1 path/to/tarball2 /path/to/tb3 

Assuming that each tarball is from a different version, you will group three servers under one directory, with the handy sandbox scripts to manipulate them.

=head2 DEFAULTS AND SHORTCUTS

If you use sandboxes often, instead of pointing to a tarball you can set a directory containing expanded tarballs.
By default, the sandbox looks under $HOME/opt/mysql and /opt/mysql

The expanded tarballs must be named with the full version.
e.g. 

  $HOME/opt/mysql/5.0.64 
  /opt/mysql/5.1.24
    
If you have such an organization, then you can invoke every sandbox script with this abridged syntax:

  make_sandbox 5.0.64
  make_replication_sandbox 5.1.25
  make_multiple_custom_sandbox 5.0.64 5.1.25

If you use some options frequently, it would make sense to add them to the default option file, which is $HOME/.msandboxrc

=head2 FINE TUNING

Every sandbox script will give you additional information if you invoke it
with the "--help" option.

When creating a single sandbox, you can pass to the new server most any option
that can be used in a my.cnf file, in addition to specific sandbox options.

Multiple and replication sandboxes, for example, accept a --how_many_slaves=X
or --how_many_nodes=X option, allowing you to create very large groups.

=head2 SANDBOX HOME

Unless you override the defaults, sandboxes are created inside a 
directory that servers two purposes:

=over 3

=item *
further isolates the sandboxes, and keep them under easy control if you are in the habit of creating many of them;

=item *
provides a set of handy super-commands, which can be passed to all the sandboxes. Running "$HOME/sandboxes/stop_all" you will stop all servers of all sandboxes, single or groups, below that directory.

=back

=head1 USING A SANDBOX

Change directory to the newly created one 
(default: $HOME/sandboxes/msb_VERSION for single sandboxes)

The sandbox directory of the instance you just created contains
some handy scripts to manage your server easily and in isolation.
 
=over 3

=item start

=item restart

=item stop
"./start", "./restart", and "./stop" do what their name suggests.

=item use
"./use" calls the command line client with the appropriate parameters,

=item clear
"./clear" stops the server and removes everything from the data directory, letting you ready to start from scratch.

=item multiple server sandbox
On a replication sandbox, you have the same commands, with a "_all"
suffix, meaning that you propagate the command to all the members.
Then you have "./m" as a shortcut to use the master, "./s1" and "./s2"
to access the slaves (and "s3", "s4" ... if you define more)

=over 3

=item start_all

=item stop_all

=item use_all

=item clear_all

=item m

=item s1,s2

=back

=back

=head2 DATABASE USERS

There are 2 database users installed by default:

 +-----------------+-------------+-------------------------------+
 |  user name      | password    | privileges                    |
 +-----------------+-------------+-------------------------------+
 |  root@localhost | msandbox    | all on *.* with grant option  |
 |  msandbox@%     | msandbox    | all on *.*                    |
 +-----------------+-------------+-------------------------------+

=head2 PORTS AND SOCKETS

Ports are created from the server version.
a 5.1.25 server will use port 5125, unless you override the default.
Replicated and group sandboxes add a delta number to the version
figure, to avoid clashing with single installations. 

(note: ports can be overriden using -P option during install)

 +--------+-----------------------------+
 | port   | socket                      |
 +--------+-----------------------------+
 |  3310  | /tmp/mysql_sandbox3310.sock |
 +--------+-----------------------------+

=head2 ENVIRONMENT VARIABLES

All programs in the Sandbox suite recognize and uses the following variables:

 * HOME the user's home directory
 * USER the operating system user
 * PATH the execution path
 * DEBUG if set, the programs will print debugging messages

In addition to the above, make_sandbox will use
 * BINARY_BASE the directory containing the installation server binaries

make_replication_sandbox will recognize the following
   * MASTER_OPTIONS additional options to be passed to the master
   * SLAVE_OPTIONS additional options to be passed to each slave

=head1 REQUIREMENTS

To use this package you need at least the following:

=over 3

=item *
Linux or Mac OSX operating system (it may work in other *NIX OSs, but has not been tested)

=item *
a binary tarball of MySQL 3.23 or later

=item *
Perl 5.8.1 or later (for installation only)

=item *
bash shell

=back


=head1 COPYRIGHT
version 3.0

Copyright © 2006,2007,2008,2009  Giuseppe Maxia
Home Page  http://launchpad.net/mysql-sandbox/

=head1 LEGAL NOTICE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
USA

