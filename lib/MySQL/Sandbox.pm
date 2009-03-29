package MySQL::Sandbox;
use strict;
use warnings;
use English qw( -no_match_vars ); 
use Socket;

# use base qw( Exporter);
# our @ISA= qw(Exporter);

our $VERSION='2.0.98';
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
    }, $class;
    # my $version = get_version( $install_dir);
    # $self->{version} = $VERSION;
    return $self;
}

sub parse_options {
    my ($self, $opt ) = @_;
    if ($opt) {
        $self->{parse_options} = $opt;
    }
    return $self->{parse_options};
}

sub get_help {
    my ($self, $msg) = @_;
    if ($msg) {
        warn "[***] $msg\n\n";
    }

    my $HELP_MSG = q{};
    for my $op ( 
                sort { $self->parse_options->{$a}{so} <=> $self->parse_options->{$b}{so} } 
                grep { $self->parse_options->{$_}{parse}}  keys %{ $self->parse_options } ) {
        my $param =  $self->parse_options->{$op}{parse};
        my $param_str = q{    };
        my ($short, $long ) = $param =~ / (?: (\w) \| )? (\S+) /x;
        if ($short) {
            $param_str .= q{-} . $short . q{ };
        } 
        $long =~ s/ = s \@? / = name/x;
        $long =~ s/ = i / = number/x;
        $param_str .= q{--} . $long;
        $param_str .= (q{ } x (40 - length($param_str)) );
        my $text_items = $self->parse_options->{$op}{help};
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


1;
__END__


