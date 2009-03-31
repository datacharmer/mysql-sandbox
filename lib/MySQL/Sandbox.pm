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

our $VERSION='2.0.98c';
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


