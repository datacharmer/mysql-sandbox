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
                    runs_as_root
                    exists_in_path
                    is_a_sandbox
                    find_safe_port_and_directory
                    first_unused_port
                    get_sandbox_params 
                    is_sandbox_running
                    get_sb_info
                    get_ports
                    get_ranges
                    use_env
                    sbinstr
                    get_option_file_contents ) ;

our $VERSION="3.0.12";
our $DEBUG;

BEGIN {
    $DEBUG = $ENV{'SBDEBUG'} || $ENV{'SBVERBOSE'} || 0;
    unless ( $ENV{SANDBOX_HOME} ) { 
        $ENV{SANDBOX_HOME} = "$ENV{HOME}/sandboxes";
    }

    if ( -d "$ENV{HOME}/sandboxes" ) {
        $ENV{SANDBOX_HOME} = $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";
    }

    unless ( $ENV{SANDBOX_BINARY} ) {
        if ( -d "$ENV{HOME}/opt/mysql") {
            $ENV{SANDBOX_BINARY} = "$ENV{HOME}/opt/mysql";
        }
    }
}

my @supported_versions = qw( 3.23 4.0 4.1 5.0 5.1 5.2 5.3 5.4 
    5.5 5.6 5.7 5.8 6.0);

our $sandbox_options_file    = "my.sandbox.cnf";
# our $sandbox_current_options = "current_options.conf";

our %default_base_port = (
    replication => 11000,
    circular    => 14000,
    multiple    =>  7000,
    custom      =>  5000,
); 

our $SBINSTR_SH_TEXT =<<'SBINSTR_SH_TEXT';
if [ -f "$SBINSTR" ] 
then
    echo "[`basename $0`] - `date "+%Y-%m-%d %H:%M:%S"` - $@" >> $SBINSTR
fi
SBINSTR_SH_TEXT



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

   my $VAR_HELP = 
    "\nVARIABLES affecting this program: \n"
        . "\t\$SBDEBUG : DEBUG LEVEL (" 
            . ($ENV{SBDEBUG} || 0) . ")\n"
        . "\t\$SBVERBOSE : DEBUG LEVEL (same as \$SBDEBUG) (" 
            . ($ENV{SBVERBOSE} || 0)  . ")\n"

        . "\t\$SANDBOX_HOME : root of all sandbox installations (" 
            . use_env($ENV{SANDBOX_HOME}) . ")\n"

        . "\t\$SANDBOX_BINARY : where to search for binaries (" 
            . use_env($ENV{SANDBOX_BINARY}) . ")\n"
   ;

    if ( $PROGRAM_NAME =~ /replication|multiple/ ) { 
        $VAR_HELP .= 
            "\t\$NODE_OPTIONS : options to pass to all node installations (" 
            . ($ENV{NODE_OPTIONS} || '') . ")\n"
    }

    if ( $PROGRAM_NAME =~ /replication/ ) { 
        $VAR_HELP .= 
            "\t\$MASTER_OPTIONS : options to pass to the master installation (" 
            . ($ENV{MASTER_OPTIONS} || '') . ")\n"

           . "\t\$SLAVE_OPTIONS : options to pass to all slave installations (" 
            . ($ENV{SLAVE_OPTIONS} || '' ) . ")\n"
    }
   my $target = '';
   if ( grep {$PROGRAM_NAME =~ /$_/ } 
          qw( make_sandbox make_replication_sandbox
              make_multiple_sandbox make_multiple_sandbox ) )
   {
        $target = '{tarball|dir|version}';
        $HELP_MSG =
              "tarball = the full path to a MySQL binary tarball\n"
            . "dir     = the path to an expanded MySQL binary tarball\n"
            . "version = the simple version number of the expanded tarball\n"
            . "          if it is under \$SANDBOX_BINARY and renamed as the\n "
            . "          version number.\n\n"
            . $HELP_MSG;
   } 
    
   print $self->credits(),
          "syntax: $PROGRAM_NAME [options] $target \n", 
          $HELP_MSG,
          $VAR_HELP; 
          # This example is only relevant for a single sandbox, but it is
          # wrong for a multiple sandbox.
          #, 
          #"\nExample:\n",
          #"     $PROGRAM_NAME --my_file=large --sandbox_directory=my_sandbox\n\n";

    exit(1);
}

sub credits {
    my ($self) = @_;
    my $CREDITS = 
          qq(    The MySQL Sandbox,  version $VERSION\n) 
        . qq(    (C) 2006-2010 Giuseppe Maxia\n);
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
    if (($mode eq '>') && ( $contents =~ m/\#!\/bin\/sh/ ) ) {
        print $FILE $SBINSTR_SH_TEXT;    
    }
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
#    if ( -f "$dir/$sandbox_current_options" ) {
#        $params{conf} =
#          get_option_file_contents("$dir/$sandbox_current_options");
#    }
#    else {
#        # warn "current conf file not found\n";
#        return;
#    }
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
            follow  => 1,
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
         # $sandbox_current_options, 
         $sandbox_options_file );
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
    my ($options, $silent ) = @_;
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
    unless ($silent) {
        printf "%5d - %5d\n", $minimum_port , $minimum_port + $range_size;
    }
    return $minimum_port;
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

sub exists_in_path {
    my ($cmd) = @_;
    my @path_directories = split /:/, $ENV{PATH}; ## no critic
    for my $dir (@path_directories) {
        if ( -x "$dir/$cmd") {
            return 1;
        } 
    }
    return 0;
}

sub runs_as_root {
    if ( ($REAL_USER_ID == 0) or ($EFFECTIVE_USER_ID == 0)) {
        unless ($ENV{SANDBOX_AS_ROOT}) {
            die   "MySQL Sandbox should not run as root\n"
                . "\n"
                . "If you know what you are doing and want to\n "
                . "run as root nonetheless, please set the environment\n"
                . "variable 'SANDBOX_AS_ROOT' to a nonzero value\n";
        }
    }
}

#
# Replaces a path portion with an environment variable name
# if a match is found
#
sub use_env{
    my ($path) = @_;
    my @vars = (
            'HOME', 
            'SANDBOX_HOME',
    );
    return '' unless $path;
    for my $var (@vars) {
        if ($path =~ /^$ENV{$var}/) {
            $path =~ s/$ENV{$var}/\$$var/;
            return $path;
        }
    }
    return $path;
}

sub sbinstr {
    my ($msg) = @_;
    unless ($ENV{SBINSTR}) {
        return;
    }
    my $pname = $PROGRAM_NAME;
    unless ($DEBUG) {
        $pname =~ s{.*/}{};
    }
    open my $FH, '>>', $ENV{SBINSTR}
        or die "can't write to $ENV{SBINSTR} ($!)\n";
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $mon++;
    $year +=1900;
    print $FH "[$pname] - ", 
        sprintf('%4d-%02d%02d %02d:%02d:%02d', 
                $year, $mon, $mday, $hour, $min, $sec), 
        " - $msg \n";
    close $FH;
} 

1;
__END__

=head1 NAME

MySQL::Sandbox - Quickly installs MySQL side server, either standalone or in groups

=head1 SYNOPSIS

 make_sandbox /path/to/MySQL-VERSION.tar.gz

 make_sandbox $HOME/opt/mysql/VERSION

 make_sandbox VERSION

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

Notice that PERL5LIB could be different in different operating systems. If you opt for this installation method, you must adapt it to your operating system path and Perl version.

See also under L</"TESTING"> for more options before running 'make test'

=head1 MAKING SANDBOXES

=head2 Single server sandbox

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

   $SANDBOX_HOME/msb_X_X_XX


=head2 Making a replication sandbox

It's as easy as making a single sandbox

   $ make_replication_sandbox /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a new instance of one master  and two slaves

   under $SANDBOX_HOME/rsandbox_X_X_XX

=head2 Circular replication

It requires an appropriate option when you start a replication sandbox

   $ make_replication_sandbox --circular=4 /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a replication system with three servers connected by circular replication.
A handy shortcut is C<--master_master>, which will create a circular replication system of exactly two members.

=head2 Multiple sandboxes

You can create a group of sandboxes without any replication among its members.
If you need three servers of the same version, you can use

 $ make_multiple_sandbox /path/to/tarball 

If you need servers of different versions in the same group, you may like

 $ make_multiple_custom_sandbox /path/to/tarball1 path/to/tarball2 /path/to/tb3 

Assuming that each tarball is from a different version, you will group three servers under one directory, with the handy sandbox scripts to manipulate them.

=head2 Creating a sandbox from source

If you want to create a sandbox from the code that you have just compiled, but you don't want to install, there is a script that makesa binary tarball for you and installs a sandbox in one go.

 $ make_sandbox_from_source {SOURCE_DIRECTORY} {sandbox_type} [options]

The first parameters is the directory where you have successfully run "./configure && make". 
The second parameter is what kind of sandbox you want to create: One of the following:

  * single
  * multiple
  * replication
  * circular

You can then add all the options you need at the end.
For example:

 $ make_sandbox_from_source $HOME/build/5.0 single --export_binaries --check_port 

or

 $ make_sandbox_from_source $HOME/build/5.0 replication --how_many_slaves=5

If you call this program several times from the same directory, it will check if the compiled binaries are newer than the extracted ones, and if they aren't, it will reuse the ones created during the previous run, thus saving time and CPU.

=head2 Creating a sandbox from already installed binaries

The script C<make_sandbox_from_installed> tries to create a sandbox using already installed binaries.
Since these binaries can be in several different places, the script creates a container with symbolic links, where the binaries (their links, actually) are arranged as MySQL Sandbox expects them to be.

To use this version, change directory to a place where you want to store this symbolic links container, and invoke

  make_sandbox_from_installed X.X.XX [options]

where X.X.XX is the version number. You can then pass any options accepted by make_sandbox.

=head2 Defaults and shortcuts

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

=head2 Fine tuning

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

provides a set of handy super-commands, which can be passed to all the sandboxes. Running "$SANDBOX_HOME/stop_all" you will stop all servers of all sandboxes, single or groups, below that directory.

=back

=head1 USING A SANDBOX

Change directory to the newly created one 
(default: $SANDBOX_HOME/msb_VERSION for single sandboxes)

The sandbox directory of the instance you just created contains
some handy scripts to manage your server easily and in isolation.

=over 3

=item start

=item restart

=item stop

"./start", "./restart", and "./stop" do what their name suggests.
C<start> and C<restart> accept parameters that are eventually passed to the server. e.g.:

  ./start --skip-innodb

  ./restart --event-scheduler=disabled

=item use

"./use" calls the command line client with the appropriate parameters,

=item clear

"./clear" stops the server and removes everything from the data directory, letting you ready to start from scratch.

=item multiple server sandbox

On a replication sandbox, you have the same commands, with a "_all"
suffix, meaning that you propagate the command to all the members.
Then you have "./m" as a shortcut to use the master, "./s1" and "./s2"
to access the slaves (and "s3", "s4" ... if you define more).

In group sandboxes without a master slave relationship (circular replication and multiple sandboxes) the nodes can be accessed by ./n1, ./n2, ./n3, and so on.

=over 3

=item start_all

=item restart_all

=item stop_all

=item use_all

=item clear_all

=item m

=item s1,s2

=back

=back

=head2 Database users

There are 2 database users installed by default:

 +-----------------+-------------+-------------------------------+
 |  user name      | password    | privileges                    |
 +-----------------+-------------+-------------------------------+
 |  root@localhost | msandbox    | all on *.* with grant option  |
 |  msandbox@%     | msandbox    | all on *.*                    |
 +-----------------+-------------+-------------------------------+

=head2 Ports and sockets

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

=head2 Searching for free ports

MySQL Sandbox uses a fairly reasonable system of default ports that 
guarantees the usage of unused ports most of the times. 
If you are creating many sandbozes, however, especially if you want
several sandboxes using the same versions, collisions may happen.
In these cases, you may ask for a port check before installing, thus 
making sure that your sandbox is really not conflicting with anything.

=head3 Single sandbox port checking

The default behavior when asking to install a sandbox over an existing 
one is to abort. If you specify the C<--force> option, the old sandbox
will be overwritten.
Instead, using the C<--check_port> option, MySQL Sandbox searches for the
first available unused port, and uses it. It will also create a non 
conflicting data directory. For example

 make_sandbox 5.0.79
 # creates a sandbox with port 5079 under $SANDBOX_HOME/msb_5_0_79

A further call to the same command will be aborted unless you specify 
either C<--force> or C<--check_port>.

 make_sandbox 5.0.79 --force
 # Creates a sandbox with port 5079 under $SANDBOX_HOME/msb_5_0_79
 # The contents of the previous data directory are removed.

 make_sandbox 5.0.79 --check_port
 # Creates a sandbox with port 5080 under $SANDBOX_HOME/msb_5_0_79_a

 make_sandbox 5.0.79 --check_port
 # Creates a sandbox with port 5081 under $SANDBOX_HOME/msb_5_0_79_b

Notice that this option is disabled when you use a group sandbox (replication or multiple). Even if you set NODE_OPTIONS=--check_port, it won't be used, because every group sandbox invokes make_sandbox with the --no_check_port option.

=head3 Multiple sandbox port checking

When you create a multiple sandbox (make_replication_sandbox, 
make_multiple_sandbox, make_multiple_custom_sandbox) the default behavior
is to overwrite the existing sandbox without asking for confirmation. 
The rationale is that a multiple sandbox is definitely more likely to be a 
created only for testing purposes, and overwriting it should not be a problem.
If you want to avoid overwriting, you can specify a different group name
(C<--replication_directory> C<--group_directory>), but this will use the
same base port number, unless you specify C<--check_base_port>.

 make_replication_sandbox 5.0.79
 # Creates a replication directory under $SANDBOX_HOME/rsandbox_5_0_79
 # The default base_port is 7000

 make_replication_sandbox 5.0.79
 # Creates a replication directory under $SANDBOX_HOME/rsandbox_5_0_79
 # overwriting the previous one. The default base port is still 7000

 # WRONG
 make_replication_sandbox --check_base_port 5.0.79
 # Creates a replication directory under $SANDBOX_HOME/rsandbox_5_0_79
 # overwriting the previous one. 

 # WRONG
 make_replication_sandbox --replication_directory=newdir 5.0.79
 # Created a replication directory under $SANDBOX_HOME/newdir.
 # The previous one is preserved, but the new sandbox does not start
 # because of port conflict.

 # RIGHT
 make_replication_sandbox --replication_directory=newwdir \
    --check_base_port 5.0.79
 # Creates a replication directory under $SANDBOX_HOME/newdir
 # The previous one is preserved. No conflicts happen

=head2 Environment variables

All programs in the Sandbox suite recognize and use the following variables:

 * HOME the user's home directory; ($HOME)
 * SANDBOX_HOME the place where the sandboxes are going to be built. 
   ($HOME/sandboxes by default)
 * USER the operating system user;
 * PATH the execution path;
 * if SBDEBUG if set, the programs will print debugging messages

In addition to the above, make_sandbox will use
 * SANDBOX_BINARY or BINARY_BASE 
   the directory containing the installation server binaries
   (default: $HOME/opt/mysql) 

make_replication_sandbox will recognize the following
   * MASTER_OPTIONS additional options to be passed to the master
   * SLAVE_OPTIONS additional options to be passed to each slave
   * NODE_OPTIONS additional options to be passed to each node

The latter is also recognized by 
make_multiple_custom_sandbox and make_multiple_sandbox 

The test suite, C<test_sandbox>, recognizes two environment variables

 * TEST_SANDBOX_HOME, which sets the path where the sandboxes are
   installed, if the default $HOME/test_sb is not suitable. It is used
   when you test the package with 'make test'
 * PRESERVE_TESTS. If set, this variable prevents the removal of test
   sandboxes created by test_sandbox. It is useful to inspect sandboxes
   if a test fails.

=head2 sb - the Sandbox shortcut

When you have many sandboxes, even the simple exercise of typing the path to the appropriate 'use' script can be tedious and seemingly slow.

If saving a few keystrokes is important, you may consider using C<sb>, the sandbox shortcut.
You invoke 'sb' with a version number, without dots or underscores. The shortcut script will try its best at finding the right directory.

  $ sb 5135
  # same as calling 
  # $SANDBOX_HOME/msb_5_1_35/use

Every option that you use after the version is passed to the 'use' script.

  $ sb 5135 -e "SELECT VERSION()"
  # same as calling 
  # $SANDBOX_HOME/msb_5_1_35/use -e "SELECT VERSION()"

Prepending a "r" to the version number indicates a replication sandbox. If the directory is found, the script will call the master.

  $ sb r5135
  # same as calling 
  # $SANDBOX_HOME/rsandbox_5_1_35/m

To use a slave, use the corresponding number immediately after the version.

  $ sb r5135 2
  # same as calling 
  # $SANDBOX_HOME/rsandbox_5_1_35/s2

Options for the destination script are added after the node indication.

  $ sb r5135 2 -e "SELECT 1"
  # same as calling 
  # $SANDBOX_HOME/rsandbox_5_1_35/s2 -e "SELECT 1"

Similar to replication, you can call multiple sandboxes, using an 'm' before the version number.

  $ sb m5135
  # same as calling 
  # $SANDBOX_HOME/multi_msb_5_1_35/n1

  $ sb m5135 2
  # same as calling 
  # $SANDBOX_HOME/multi_msb_5_1_35/n2

If your sandbox has a non-standard name and you pass such name instead of a version, the script will attempt to open a single sandbox with that name.

  $ sb testSB
  # same as calling 
  # $SANDBOX_HOME/testSB/use

If the identified sandbox is not active, the script will attempt to start it.

This shortcut script doesn't deal with any sandbox script other than the ones listed in the above examples.

But the sb can do even more. If you invoke it with a dotted version number, the script will run the appropriate make*sandbox script and then use the sandbox itself.

  $ sb 5.1.35
  # same as calling 
  # make_sandbox 5.1.35 --no_confirm
  # and then
  # $SANDBOX_HOME/msb_5_1_35/use

It works for group sandboxes as well.

  $ sb r5.1.35
  # same as calling 
  # make_replication_sandbox 5.1.35 
  # and then
  # $SANDBOX_HOME/rsandbox_5_1_35/m

And finally, it also does What You Expect when using a tarball instead of a version.

  $ sb mysql-5.1.35-YOUR_OS.tar.gz
  # creates and uses a single sandbox from this tarball

  $ sb r mysql-5.1.35-YOUR_OS.tar.gz
  # creates and uses a replication sandbox from this tarball

  $ sb m mysql-5.1.35-YOUR_OS.tar.gz
  # creates and uses a multiple sandbox from this tarball

Using a MySQL server has never been easier.

=head1 SBTool the Sandbox helper

The Sandbox Helper, C<sbtool>, is a tool that allows administrative operations 
on already existing sandboxes. It does a number of important tasks that are
not available at creation time or that would require too much manual labor.

    usage: sbtool [options] 
    -o     --operation       (s) <> - what task to perform
         'info'     returns configuration options from a Sandbox
         'copy'     copies data from one Sandbox to another
         'ports'    lists ports used by the Sandbox
         'tree'     creates a replication tree
         'move'     moves a Sandbox to a different location
         'range'    finds N consecutive ports not yet used by the Sandbox
         'port'     Changes a Sandbox port
         'delete'   removes a sandbox completely
         'preserve' makes a sandbox permanent
         'unpreserve' makes a sandbox NOT permanent
         'plugin'   installs a given plugin
    -s     --source_dir      (s) <> - source directory for move,copy
    -d     --dest_dir        (s) <> - destination directory for move,copy
    -n     --new_port        (s) <> - new port while moving a sandbox
    -u     --only_used       (-) <> - for "ports" operation, shows only the used ones
    -i     --min_range       (i) <5000> - minimum port when searching for available ranges
    -x     --max_range       (i) <64000> - maximum port when searching for available ranges
    -z     --range_size      (i) <10> - size of range when searching for available port range
    -f     --format          (s) <text> - format for "ports" and "info"
         'perl'     fully structured information in Perl code
         'text'     plain text dump of requested information
    -p     --search_path     (s) </Users/gmax/sandboxes> - search path for ports and info
    -a     --all_info        (-) <> - print more info for "ports" operation
           --tree_nodes      (s) <> - description of the tree (x-x x x-x x|x x x|x x)
           --mid_nodes       (s) <> - description of the middle nodes (x x x)
           --leaf_nodes      (s) <> - description of the leaf nodes (x x|x x x|x x)
           --tree_dir        (s) <> - which directory contains the tree nodes
           --plugin          (s) <> - which plugin needs to be installed
           --plugin_file     (s) <> - which plugin template file should be used
    -v     --verbose         (-) <> - prints more info on some operations
    -h     --help            (-) <1> - this screen

=head2 sbtool - Informational options

=head3  sbtool -o info     

Returns configuration options from a Sandbox (if specified) or from all sandboxes 
under $SANDBOX_HOME (default).
You can use C<--search_path> to tell sbtool where to start. 
The return information is formatted as a Perl structure.

=head3 sbtool -o ports

Lists ports used by the Sandbox. Use C<--search_path> to tell sbtool where to 
start looking (default is $SANDBOX_HOME). You can also use the C<--format> option
to influence the outcome. Currently supported are only 'text' and 'perl'.
If you add the C<--only_used> option, sbtool will return only the ports that are 
currently open.

=head3 sbtool -o range

Finds N consecutive ports not yet used by the Sandbox. 
It uses the same options used with 'ports' and 'info'. Additionally, you can
define the low and high boundaries by means of C<--min_range> and C<--max_range>.
The size of range to search is 10 ports by default. It can be changed 
with C<--range_size>.

=head2 sbtool - modification options

=head3 sbtool -o port

Changes port to an existing Sandbox.
This requires the options C<--source_dir> and C<--new_port> to complete the task.
If the sandbox is running, it will be stopped.  

=head3 sbtool -o copy

Copies data from one Sandbox to another.
It only works on B<single> sandboxes.
It requires the C<--source_dir> and C<--dest_dir> options to complete the task.
Both Source and destination directory must be already installed sandboxes. If any 
of them is still running, it will be stopped. If both source and destination directory
point to the same directory, the command is not performed.
At the end of the operation, all the data in the source sandbox is copied to
the destination sandbox. Existing files will be overwritten. It is advisable, but not
required, to run a "./clear" command on the destination directory before performing 
this task.

=head3 sbtool -o move

Moves a Sandbox to a different location.
Unlike 'copy', this operation acts on the whole sandbox, and can move both single
and multiple sandboxes.
It requires the C<--source_dir> and C<--dest_dir> options to complete the task.
If the destination directory already exists, the task is not performed. If the source
sandbox is running, it will be stopped before performing the operation.
After the move, all paths used in the sandbox scripts will be changed.

=head3 sbtool -o tree

Creates a replication tree, with one master, one or more intermediate level slaves,
and one or more leaf node slaves for each intermediate level.
To create the tree, you need to create a multiple nodes sandbox (using C<make_multiple_sandbox>)
and then use C<sbtool> with the following options:

 * --tree_dir , containing the sandbox to convert to a tree
 * --master_node, containing the node that will be master
 * --mid_nodes, with a list of nodes for the intermediate level
 * --leaf_nodes, with as many lists as how many mid_nodes
   Each list is separated from the next by a pipe sign (|).

Alternatively, you can use the C<--tree_nodes> option to describe all
the tree at once.

For example, in a sandbox with 8 nodes, to define 1 as master node, 
nodes 2 and 3 as  middle nodes, nodes 4, 5, and 6 as slaves of node 2
and nodes 7 and 8 as slaves of node 3, you can use either of the following:

 sbtool --tree_dir=/path/to/source \
    --master_node=1 \
    --mid_nodes='2 3'
    --leaf_nodes='4 5 6|7 8'

 sbtool --tree_dir=/path/to/source \
    --tree_nodes='1 - 2 3 - 4 5 6|7 8' 

=head3 sbtool -o preserve

Makes a sandbox permanent.
It requires the C<--source_dir> option to complete the task.
This command changes the 'clear' command within the requested sandbox,
disabling its effects. The sandbox can't be erased using 'clear' or 'clear_all'.
The 'delete' operation of sbtool will skip a sandbox that has been made permanent.

=head3 sbtool -o unpreserve

Makes a sandbox NOT permanent.
It requires the C<--source_dir> option to complete the task.
This command cancels the changes made by a 'preserve' operation, making a sandbox
erasable with the 'clear' command. The 'delete' operation can be performed 
successfully on an unpreserved sandbox.

=head3 sbtool -o delete

Removes a sandbox completely.
It requires the C<--source_dir> option to complete the task.
The requested sandbox will be stopped and then deleted completely. 
WARNING! No confirmation is asked!

=head3 sbtool -o plugin

Installs a given plugin into a sandbox.
It requires the C<--source_dir> and C<--plugin> options to complete the task.
The plugin indicated must be defined in the plugin template file, which is by default installed in C<$SANDBOX_HOME>. 
Optionally, you can indicate a different plugin template with the C<--plugin_file> option.
By default, sbtool looks for the plugin template file in the sandbox directory that is the target of the installation. If it is not found there, it will look at C<$SANDBOX_HOME> before giving up with an error.

=head4 Plugin template

The Plugin template is a Perl script containing the definition of the templates you want to install.
Each plugin must have at least one target B<Server type>, which could be one of I<all_servers>, I<master>, or I<slave>. It is allowed to have more than one target types in the same plugin. 

Each server type, in turn, must have at least one section named B<operation_sequence>, an array reference containing the list of the actions to perform. Such actions can be regular scripts in each sandbox (start, stop, restart, clear) or one of the following template sections:

=over 3

=item options_file 

It is the list of lines to add to an options file, under the C<[mysqld]> label.

=item sql_commands 

It is a list of queries to execute. Every query must have appropriate semicolons as required. If no semicolon are found in the list, no queries are executed.

=item startup_file

It is a file, named I<startup.sql>, to be created under the data directory. It will contain the lines indicated in this section.
You must remember to add a line 'init-file=startup.sql' to the options_file section.

=back

=head1 TESTING

=head2 test_sandbox

The MySQL Sandbox comes with a test suite, called test_sandbox, which by
default tests single,replicated, multiple, and custom installations of MySQL
version 5.0.77 and 5.1.32.You can override the version being tested by means
of command line options:

 test_sandbox --versions=5.0.67,5.1.30

or you can specify a tarball

 test_sandbox --versions=/path/to/mysql-tarball-5.1.31.tar.gz
 test_sandbox --tarball=/path/to/mysql-tarball-5.1.31.tar.gz

You can also define which tests you want to run:

  test_sandbox --tests=single,replication

=head2 Test isolation

The tests are not performed in the common C<$SANDBOX_HOME> directory, but 
on a separate directory, which by default is C<$HOME/test_sb>. To avoid 
interferences, before the tests start, the application runs the 
C<$SANDBOX_HOME/stop_all> command.
The test directory is considered to exist purely for testing purposes, and
it is erased several times while running the suite. Using this directory 
to store valuable data is higly risky.


=head2 Tests during installation

When you build the package and run 

  make test

test_sandbox is called, and the tests are performed on a temporary directory
under C<$INSTALLATION_DIRECTORY/t/test_sb>. By default, version 5.0.77 is used.
If this version is not found in C<$HOME/opt/mysql/>, the test is skipped.
You can override this option by setting the TEST_VERSION environment variable.

  TEST_VERSION=5.1.30 make test
  TEST_VERSION=$HOME/opt/mysql/5.1.30 make test
  TEST_VERSION=/path/to/myswl-tarball-5.1.30.tar.gz make test

=head2 User defined tests

Starting with version 2.0.99, you can define your own tests, and run them by

  $ test_sandbox --user_test=file_name

=head3 simplified test script

Inside your test file, you can define test actions.
There are two kind of tests: shell and sql the test type is defined by a keyword followed by a colon.

The 'shell' test requires a 'command', which is passed to a shell.
The 'expected' label is a string that you expect to find within the shell output.
If you don't expect anything, you can just say "expected = OK", meaning that you will
be satisfied with a ZERO exit code reported by the operating system.
The 'msg' is the description of the test that is shown to you when the test runs.

  shell:
  command  = make_sandbox 5.1.30 --no_confirm
  expected = sandbox server started
  msg      = sandbox creation

The 'sql' test requires a 'path', which is the place where the test engine expects to find a 'use' script.
The 'query' is passed to the above mentioned script and the output is captured for further processing.
The 'expected' parameter is a string that you want to find in the query output.
The 'msg' parameter is like the one used with the 'shell' test.

  sql:
  path    = $SANDBOX_HOME/msb_5_1_30
  query   = select version()
  expected = 5.1.30
  msg      = checking version

All strings starting with a $ are expanded to their corresponding environment variables. 
For example, if $SANDBOX_HOME is /home/sb/tests, the line 

  command  = $SANDBOX_HOME/msb_5_1_30/stop

will expand to:

  command = /home/sb/tests/msb_5_1_30/stop

=head3 Perl based test scripts

In addition to the internal script language, you can also define perl scripts, which will be able to use the $sandbox_home global variable and to call routines defined inside test_sandbox. (see list below)
To be identified as a Perl script, the user defined test must have the extension ".sb.pl"

=over 3

=item ok_shell()

The C<ok_shell> function requires a hash reference containing the following labels:
A 'command', which is passed to a shell.
The 'expected' label is a string that you expect to find within the shell output.
If you don't expect anything, you can just say "expected = OK", meaning that you will
be satisfied with a ZERO exit code reported by the operating system.
The 'msg' is the description of the test that is shown to you when the test runs.

  ok_shell($hashref)
  ok_shell({
        command  => 'make_sandbox 5.1.30 --no_confirm',
        expected => 'sandbox server started',
        msg      => 'sandbox creation',
        })

=item ok_sql()  

The C<ok_sql> function requires a hashref containing the following labels:
A 'path', which is the place where the test engine expects to find a 'use' script.
The 'query' is passed to the above mentioned script and the output is captured for further processing.
The 'expected' parameter is a string that you want to find in the query output.
The 'msg' parameter is like the one used with the ok_exec function.


=item get_bare_version()

This function accepts one parameter, which can be either a MySQL tarball name or a version, and returns the bare version found in the input string.
If called in list mode, it returns also a normalized version string with dots replaced by underscores.

    my $version = get_bare_version('5.1.30'); 
    # returns '5.1.30'

    my $version = get_bare_version('mysql-5.1.30-OS.tar.gz'); 
    # returns '5.1.30'

    my ($version,$dir_name) = get_bare_version('mysql-5.1.30-OS.tar.gz'); 
    # returns ('5.1.30', '5_1_30')

=item ok

This is a low level function, similar to the one provided by Test::More. You should not need to call this one directly, unless you want to fine tuning a test.

See the test script t/start_restart_arguments.sb.pl as an example

=back

=head1 REQUIREMENTS

To use this package you need at least the following:

=over 3

=item *

Linux or Mac OSX operating system (it may work in other *NIX OSs, but has not been tested)

=item *

A binary tarball of MySQL 3.23 or later

=item *

Perl 5.8.1 or later 

=item *

Bash shell

=back


=head1 COPYRIGHT

Version 3.0

Copyright (C) 2006-2010 Giuseppe Maxia

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

