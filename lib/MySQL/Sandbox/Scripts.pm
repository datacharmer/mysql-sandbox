package MySQL::Sandbox::Scripts;
use strict;
use warnings;
use MySQL::Sandbox;

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT_OK = qw( scripts_in_code);
our @EXPORT = @EXPORT_OK;

our @MANIFEST = (
'clear.sh',
'my.sandbox.cnf',
'start.sh',
'restart.sh',
'stop.sh',
'send_kill.sh',
'load_grants.sh',
'use.sh',
'proxy_start.sh',
'my.sh',
'change_paths.sh',
'change_ports.sh',
#'COPYING',
#'README',
'USING',
'grants.mysql',
# 'current_options.conf',
'# INSTALL FILES',
# 'sandbox',
##'make_sandbox',
##'low_level_make_sandbox',
##'make_replication_sandbox',
##'make_multiple_sandbox',
##'make_multiple_custom_sandbox',
##'sbtool',
'sandbox_action.pl',
#'tests/test_sandbox.pl',
#'tests/README',
#'sandbox.conf',
##'Changelog',

);

sub manifest {
    return @MANIFEST;
}
my %parse_options_low_level_make_sandbox = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory that will contain the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
 
    sandbox_directory     => {
                                value => 'msb',    
                                parse => 'd|sandbox_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox, under home-directory'
                                         ] 
                             },
    sandbox_port          => {
                                value => 3310,               
                                parse => 'P|sandbox_port=i',           
                                so    =>  30,
                                help  => [
                                            'The port number to use for the sandbox server.', 
                                            '(Default: 3310)',
                                         ]
                            },
    datadir_from          => {
                                value => 'script',          
                                parse => 'datadir_from=s' ,            
                                so    =>  40,
                                help  => [
                                            'Where to get datadir files from. Available options are',
                                            'archive   will be taken from the archived data',
                                            '          provided with the package. They include',
                                            '          default username and passwords',
                                            '          ( DEPRECATED )',
                                            'script    the script mysql_install_db is called, with',
                                            '          default users, no passwords.',
                                            'dir:name  will be copied from an existing mysql directory', 
                                            '(Default: script)',
                                         ]
                             },
    install_version       => {
                                value => '',              
                                parse => 'i|install_version=s',        
                                so    =>  50,
                                help  => [
                                            'Which version to install (3.23, 4.0, 4.1, 5.0 or 5.1) default: none'
                                         ]
                            },
   basedir               => {
                                value => '/usr/local/mysql', 
                                parse => 'b|basedir=s' ,               
                                so    =>  60,
                                help  => [
                                            'Base directory for MySQL (default: /usr/local/mysql)'
                                         ]
                            },
    my_file               => {
                                value => q{},                 
                                parse => 'm|my_file=s',                
                                so    =>  70,
                                help  => [
                                            'which sample my-{small|large|huge}.cnf file should be used',
                                            'for additional configuration',
                                            'You may enter either the label (small|large|huge) or a full',
                                            'file name. (default: none)',
                                         ]
                            },
    conf_file             => {
                                value => q{},                 
                                parse => 'f|conf_file=s',              
                                so    =>  80,
                                help  =>  [
                                            'Configuration file containing options like the ones',
                                            'you can give on the command line (without dashes)',
                                          ]
                            },
    operating_system_user => {
                                value => $ENV{'USER'},       
                                parse => 'U|operating_system_user=s',  
                                so    =>  90,
                                help  => [
                                            'Operating system user (for mysql installation)',
                                            "default: \$USER ($ENV{USER})",
                                         ]
                            },
    db_user               => {
                                value => 'msandbox',      
                                parse => 'u|db_user=s'  ,              
                                so    => 100,
                                help  => [
                                            'user for global access to mysql (Default: sandbox)'
                                         ]
                            },
    db_password           => {
                                value => 'msandbox',      
                                parse => 'p|db_password=s'  ,              
                                so    => 110,
                                help  => [
                                            'password for global access to mysql (Default: sandbox)'
                                         ]
                            },
    my_clause             => {
                                value => '',      
                                parse => 'c|my_clause=s@', 
                                so    => 120,
                                help  => [
                                            'option to be inserted in a my.cnf file',
                                            'it may be used several times',
                                         ]
                            },
    prompt_prefix           => {
                                value => 'mysql',      
                                parse => 'prompt_prefix=s', 
                                so    => 130,
                                help  => [
                                            'prefix to use in CLI prompt (default: mysql)',
                                         ]
                            },

    prompt_body          => {
                                value => q/ [\h] {\u} (\d) > '/,      
                                parse => 'prompt_body=s', 
                                so    => 135,
                                help  => [
                                            'options to use in CLI prompt (default:  [\h] {\u} (\d) > )',
                                         ]
                            },
    force                 => {
                                value => 0,                  
                                parse => 'force',                      
                                so    => 140,
                                help  => [
                                            'Use this option if you want to overwrite existing directories',
                                            'and files during the installation. (Default: disabled)', 
                                         ] 
                            },
    no_ver_after_name     => {
                                value => 0,                  
                                parse => 'no_ver_after_name',                  
                                so    => 150,
                                help  => [
                                            'Do not add version number after sandbox directory name (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 160,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
   load_grants           => {
                                value => 0,                  
                                parse => 'load_grants',                  
                                so    => 170,
                                help  => [
                                            'Loads the predefined grants from a SQL file.',
                                            'Useful when installing from script.',
                                            '(default: disabled)'
                                         ] 
                            },
   no_load_grants         => {
                                value => 0,                  
                                parse => 'no_load_grants',                  
                                so    => 175,
                                help  => [
                                            'Does not loads the predefined grants from a SQL file.',
                                            '(default: disabled)'
                                         ] 
                            },


    interactive           => {
                                value => 0,                  
                                parse => 't|interactive',                  
                                so    => 180,
                                help  => [
                                            'Use this option to be guided through the installation process (default: disabled)'
                                         ] 
                            },
    more_options          => {value => q{},                 parse => undef,                        so => 20},
    help                  => {value => q{},                 parse => 'help',                       so => 25},
    no_confirm            => {
                                value => 0, 
                                parse => 'no_confirm',
                                so    => 190,
                                help  => [
                                            'suppress the confirmation request from user',
                                         ],
                            },
);

my %parse_options_replication = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    replication_directory  => {
                                value => undef,
                                parse => 'r|replication_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox replication system, under upper-directory',
                                            'default: (rsandbox)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox replication system.', 
                                            '(Default: 11000  + version )',
                                         ]
                            },

    how_many_slaves      => {
                                value => 2,               
                                parse => 'how_many_nodes|how_many_slaves=i',           
                                so    =>  50,
                                help  => [
                                            'The number of slaves to create.', 
                                            '(Default: 2)',
                                         ]
                            },

    topology               => {
                                value => 'standard',                  
                                parse => 't|topology=s',                  
                                so    => 55,
                                help  => [
                                            'Sets a replication topology.',
                                            'Available: {standard|circular} (default: standard)'
                                         ] 
                            },
    circular               => {
                                value => 0,
                                parse => 'circular=i',                  
                                so    => 56,
                                help  => [
                                            'Sets circular replication with N nodes.',
                                            '(default: 0)'
                                         ] 
                            },


    master_master        => {
                                value => 0,                  
                                parse => 'master_master',                  
                                so    => 57,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 60,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 70,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
);


my %parse_options_many = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    group_directory  => {
                                value => undef,
                                parse => 'r|group_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox group, under home-directory',
                                            'default: (multi_msb)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox multiple system.', 
                                            '(Default: 7000  + version )',
                                         ]
                            },

    how_many_nodes      => {
                                value => 3,               
                                parse => 'how_many_nodes=i',           
                                so    =>  50,
                                help  => [
                                            'The number of nodes to create.', 
                                            '(Default: 3)',
                                         ]
                            },
    master_master        => {
                                value => 0,                  
                                parse => 'master_master',                  
                                so    => 65,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    circular             => {
                                value => 0,                  
                                parse => 'circular',                  
                                so    => 60,
                                help  => [
                                            'set the nodes in circular replication'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 70,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },

    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 80,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
); 

my %parse_options_custom_many = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    group_directory  => {
                                value => undef,
                                parse => 'r|group_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox group, under home-directory',
                                            'default: (multi_msb)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox custom system.', 
                                            '(Default: 5000  + version )',
                                         ]
                            },

    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 60,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 70,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
); 

my %scripts_in_code = (
    'start.sh' => <<'START_SCRIPT',
#!_BINBASH_
__LICENSE__
BASEDIR='_BASEDIR_'
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR_/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQLD_SAFE="$BASEDIR/bin/_MYSQLDSAFE_"
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
TIMEOUT=20
if [ -f $PIDFILE ]
then
    echo "sandbox server already started (found pid file $PIDFILE)"
else
    CURDIR=`pwd`
    cd $BASEDIR
    if [ "$DEBUG" = "" ]
    then
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $@ > /dev/null 2>&1 &
    else
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $@ > "$SBDIR/start.log" 2>&1 &
    fi
    cd $CURDIR
    ATTEMPTS=1
    while [ ! -f $PIDFILE ] 
    do
        ATTEMPTS=$(( $ATTEMPTS + 1 ))
        echo -n "."
        if [ $ATTEMPTS = $TIMEOUT ]
        then
            break
        fi
        sleep 1
    done
fi

if [ -f $PIDFILE ]
then
    echo " sandbox server started"
else
    echo " sandbox server not started yet"
fi

START_SCRIPT
'restart.sh' => <<'RESTART_SCRIPT',
#!_BINBASH_
__LICENSE__

SBDIR="_HOME_DIR_/_SANDBOXDIR_"
$SBDIR/stop
$SBDIR/start $@

RESTART_SCRIPT
    'stop.sh' => <<'STOP_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
BASEDIR=_BASEDIR_
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQL_ADMIN="$BASEDIR/bin/mysqladmin"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"

if [ -f $PIDFILE ]
then
    if [ -f $SBDIR/data/master.info ]
    then
        echo "stop slave" | $SBDIR/use -u root
    fi
    # echo "$MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf shutdown"
    $MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf shutdown
    sleep 1
fi
if [ -f $PIDFILE ]
then
    # use the send_kill script if the server is not responsive
    $SBDIR/send_kill
fi
STOP_SCRIPT

    'send_kill.sh' => <<'KILL_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
TIMEOUT=10
if [ -f $PIDFILE ]
then
    MYPID=`cat $PIDFILE`
    echo "Attempting normal termination --- kill -15 $MYPID"
    kill -15 $MYPID
    # give it a chance to exit peacefully
    ATTEMPTS=1
    while [ -f $PIDFILE ]
    do
        ATTEMPTS=$(( $ATTEMPTS + 1 ))
        if [ $ATTEMPTS = $TIMEOUT ]
        then
            break
        fi
        sleep 1
    done
    if [ -f $PIDFILE ]
    then
        echo "SERVER UNRESPONSIVE --- kill -9 $MYPID"
        kill -9 $MYPID
        rm -f $PIDFILE
    fi
fi

KILL_SCRIPT

    'use.sh' => <<'USE_SCRIPT',
#!_BINBASH_
__LICENSE__
export LD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$DYLD_LIBRARY_PATH
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
BASEDIR=_BASEDIR_
MYSQL="$BASEDIR/bin/mysql"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
if [ -f $PIDFILE ]
then
    $MYSQL --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS "$@"
#else
#    echo "PID file $PIDFILE not found "
fi
USE_SCRIPT

    'clear.sh' => <<'CLEAR_SCRIPT', 
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
cd $SBDIR
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
#
# attempt to drop databases gracefully
#
if [ -f $PIDFILE ]
then
    for D in `echo "show databases " | ./use -B -N | grep -v "^mysql$" | grep -v "^information_schema$"` 
    do
        echo 'drop database `'$D'`' | ./use 
    done
    VERSION=`./use -N -B  -e 'select version()'`
    if [ `perl -le 'print $ARGV[0] ge "5.1" ? "1" : "0" ' "$VERSION"` = "1" ]
    then
        ./use -e "truncate mysql.general_log"
        ./use -e "truncate mysql.slow_log"
    fi
fi

./stop
#./send_kill
rm -f data/`hostname`*
rm -f data/log.0*
rm -f data/*.log
rm -f data/falcon*
rm -f data/mysql-bin*
rm -f data/*relay-bin*
rm -f data/ib*
rm -f data/*.info
rm -f data/*.err
rm -f data/*.err-old
# rm -rf data/test/*

#
# remove all databases if any
#
for D in `ls -d data/*/ | grep -w -v mysql ` 
do
    rm -rf $D
done
mkdir data/test

CLEAR_SCRIPT
    'my.sandbox.cnf'  => <<'MY_SANDBOX_SCRIPT',
__LICENSE__
[mysql]
_MYSQL_PROMPT_
#

[client]
user            = _DBUSER_
password        = _DBPASSWORD_
port            = _SERVERPORT_
socket          = /tmp/mysql_sandbox_SERVERPORT_.sock

[mysqld]
user                            = _OSUSER_
port                            = _SERVERPORT_
socket                          = /tmp/mysql_sandbox_SERVERPORT_.sock
basedir                         = _BASEDIR_
datadir                         = _HOME_DIR_/_SANDBOXDIR_/data
pid-file                        = _HOME_DIR_/_SANDBOXDIR_/data/mysql_sandbox_SERVERPORT_.pid
#log-slow-queries               = _HOME_DIR_/_SANDBOXDIR_/data/msandbox-slow.log
#log                            = _HOME_DIR_/_SANDBOXDIR_/data/msandbox.log
_MORE_OPTIONS_

MY_SANDBOX_SCRIPT

    'USING' => <<'USING_SCRIPT',
Currently using _INSTALL_VERSION_ with basedir _BASEDIR_

USING_SCRIPT

    'grants.mysql'  => <<'GRANTS_MYSQL',

use mysql;
set password=password('_DBPASSWORD_');
grant all on *.* to _DBUSER_ identified by '_DBPASSWORD_';
delete from user where password='';
delete from db where user='';
flush privileges;

GRANTS_MYSQL

    'load_grants.sh' => << 'LOAD_GRANTS_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR=_HOME_DIR_/_SANDBOXDIR_
echo "source $SBDIR/grants.mysql" | $SBDIR/use -u root --password= 
LOAD_GRANTS_SCRIPT

    'my.sh'    => <<'MY_SCRIPT',
#!_BINBASH_
__LICENSE__

if [ "$1" = "" ]
then
    echo "syntax my sql{dump|binlog|admin} arguments"
    exit
fi

SBDIR=_HOME_DIR_/_SANDBOXDIR_
BASEDIR=_BASEDIR_
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQL=$BASEDIR/bin/mysql

SUFFIX=$1
shift

MYSQLCMD="$BASEDIR/bin/my$SUFFIX"

if [ -f $MYSQLCMD ]
then
    $MYSQLCMD --defaults-file=$SBDIR/my.sandbox.cnf "$@"
else
    echo "$MYSQLCMD not found "
fi

MY_SCRIPT
    'proxy_start.sh'    => <<'PROXY_START_SCRIPT',
#!_BINBASH_
__LICENSE__

PROXY_BIN=/usr/local/sbin/mysql-proxy
HOST='127.0.0.1'

$PROXY_BIN --proxy-backend-addresses=$HOST:_SERVERPORT_ "$@"

PROXY_START_SCRIPT

'change_ports.sh' => <<'CHANGE_PORTS_SCRIPT',
#!_BINBASH_
__LICENSE__

OLD_PORT=_SERVERPORT_

if [ "$1" = "" ]
then
    echo "new port required"
    exit
else
    NEW_PORT=$1
fi

if [ $OLD_PORT = $NEW_PORT ]
then
    echo Old port and new port must be different.
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/sandbox$old/sandbox$new/g;'
PERL_SCRIPT3='s/\b$old\b/$new/' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2 $PERL_SCRIPT3"

SCRIPTS1="start stop send_kill clear restart my.sandbox.cnf "
SCRIPTS2="load_grants my use current_options.conf $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"
for SCRIPT in $SCRIPTS
do
    perl -i.port.bak -pe "$PERL_SCRIPT" $OLD_PORT $NEW_PORT $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.port.bak"

CHANGE_PORTS_SCRIPT

    'change_paths.sh' => <<'CHANGE_PATHS_SCRIPT',
#!_BINBASH_
__LICENSE__
if [ "$1" = "" ]
then
    OLD_SB_LOCATION=_HOME_DIR_/_SANDBOXDIR_
else
    OLD_SB_LOCATION=$1
fi

if [ "$2" = "" ]
then
    NEW_SB_LOCATION=$PWD
else
    NEW_SB_LOCATION=$2
fi

if [ $OLD_SB_LOCATION = $NEW_SB_LOCATION ]
then
    echo Old location and new location must be different.
    echo Move the sandbox to the new location and then run this script.
    exit
fi

if [ ! -d "$NEW_SB_LOCATION" ]
then
    echo "new location must be a directory"
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/\b$old\b/$new/g' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2"

SCRIPTS1="start stop send_kill clear restart my.sandbox.cnf "
SCRIPTS2="load_grants my use current_options.conf $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"

for SCRIPT in $SCRIPTS
do
    perl -i.bak -pe "$PERL_SCRIPT" $OLD_SB_LOCATION $NEW_SB_LOCATION $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.path.bak"
CHANGE_PATHS_SCRIPT
    'sandbox_action.pl' => <<'SANDBOX_ACTION_SCRIPT',
#!/usr/bin/perl
__LICENSE__
use strict;
use warnings;
use MySQL::Sandbox;

my $DEBUG = $MySQL::Sandbox::DEBUG;

my $action = shift
    or die "action required {use|start|stop|clear}\n";
$action =~/^(use|start|stop|clear|send_kill)$/ 
    or die "action must be one of {use|start|stop|clear|send_kill}\n";
my $sandboxdir = $0;
$sandboxdir =~ s{[^/]+$}{};
$sandboxdir =~ s{/$}{};
my $command = shift;
if ($action eq 'use' and !$command) {
    die "action 'use' requires a command\n";
}

my @dirs = glob("$sandboxdir/*");

for my $dir (@dirs) {
    if (-d $dir) {
        if ($action eq "use") {
            if ( -x "$dir/use_all" ) {
                print "executing -- $dir/use_all $command\n" if $DEBUG;
                system(qq($dir/use_all "$command"));
            }           
            elsif ( -x "$dir/use" ) {
                print "executing -- $dir/use $command\n" if $DEBUG;
                system(qq(echo "$command" | $dir/use));
            }           
        } 
        elsif ( -x "$dir/${action}_all") {
            print "-- executing  $dir/${action}_all\n" if $DEBUG;
            system("$dir/${action}_all")
        }
        elsif ( -x "$dir/$action") {
            print "-- executing  $dir/$action\n" if $DEBUG;
            system("$dir/$action")
        }
    }
}

SANDBOX_ACTION_SCRIPT

);

my $license_text = <<'LICENSE';
#    The MySQL Sandbox
#    Copyright (C) 2006,2007,2008 Giuseppe Maxia, MySQL AB
#    Contacts: http://datacharmer.org
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
LICENSE

sub license_text {
    return $license_text;
}

sub parse_options_low_level_make_sandbox {
    return \%parse_options_low_level_make_sandbox;
}

sub parse_options_replication {
    return \%parse_options_replication;
}

sub parse_options_many {
    return \%parse_options_many;
}

sub parse_options_custom_many {
    return \%parse_options_custom_many;
}

sub scripts_in_code {
    return \%scripts_in_code;
}

1;

