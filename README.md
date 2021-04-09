# NAME

MySQL::Sandbox - Quickly installs one or more MySQL servers (or forks) in the same host, either standalone or in groups

# SYNOPSIS

    make_sandbox /path/to/MySQL-VERSION.tar.gz

    export SANDBOX_BINARY=$HOME/opt/mysql
    make_sandbox --export_binaries /path/to/MySQL-VERSION.tar.gz

    make_sandbox $SANDBOX_BINARY/VERSION

    make_sandbox VERSION

# WARNING

This project is replaced by [dbdeployer](https://github.com/datacharmer/dbdeployer), which is now GA. It can already support all MySQL-Sandbox features, plus many new ones. This project is now archived and will not be updated.

# PURPOSE

This package is a sandbox for testing features under any version of
MySQL from 3.23 to 8.0 (and any version of MariaDB.)

It will install one node under your home directory, and it will
provide some useful commands to start, use and stop this sandbox.

With this package you can play with new MySQL releases without needing
to use other computers. The server installed in the sandbox use 
non-standard data directory, ports and sockets, so they won't 
interfere with existing MYSQL installations.

# INSTALLATION

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
    export PERL5LIB=$HOME/usr/local/lib/perl5/site_perl/x.x.x
    perl Makefile.PL PREFIX=$HOME/usr/local
    make
    make test
    make install

Notice that PERL5LIB could be different in various operating systems. If you opt for this installation method, you must adapt it to your operating system path and Perl version.

See also under ["TESTING"](#testing) for more options before running 'make test'

# MAKING SANDBOXES

## Single server sandbox

The easiest way to make a sandbox is 

1. download the sandbox package and install it as instructed above
2. download a MySQL binary tarball
3. run this command

        $ make_sandbox  /path/to/mysql-X.X.XX-osinfo.tar.gz

That's all it takes to get started. The Sandbox will ask you for confirmation, and then it will tell you where it has installed your server. 

By default, the sandbox creates a new instance for you under

    $SANDBOX_HOME/msb_X_X_XX

## Making a replication sandbox

It's as easy as making a single sandbox

    $ make_replication_sandbox /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a new instance of one master and two slaves

    under $SANDBOX_HOME/rsandbox_X_X_XX

## Circular replication

It requires an appropriate option when you start a replication sandbox

    $ make_replication_sandbox --circular=4 /path/to/mysql-X.X.XX-osinfo.tar.gz

This will create a replication system with three servers connected by circular replication.
A handy shortcut is `--master_master`, which will create a circular replication system of exactly two members.

## Multiple sandboxes

You can create a group of sandboxes without any replication among its members.
If you need three servers of the same version, you can use

    $ make_multiple_sandbox /path/to/tarball 

If you need servers of different versions in the same group, you may like

    $ make_multiple_custom_sandbox /path/to/tarball1 path/to/tarball2 /path/to/tb3 

Assuming that each tarball is from a different version, you will group three servers under one directory, with the handy sandbox scripts to manipulate them.

## Creating a sandbox from source

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

## Creating a sandbox from already installed binaries

The script `make_sandbox_from_installed` tries to create a sandbox using already installed binaries.
Since these binaries can be in several different places, the script creates a container with symbolic links, where the binaries (their links, actually) are arranged as MySQL Sandbox expects them to be.

To use this version, change directory to a place where you want to store this symbolic links container, and invoke

    make_sandbox_from_installed X.X.XX [options]

where X.X.XX is the version number. You can then pass any options accepted by make\_sandbox.

## Defaults and shortcuts

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

## Fine tuning

Every sandbox script will give you additional information if you invoke it
with the "--help" option.

When creating a single sandbox, you can pass to the new server most any option
that can be used in a my.cnf file, in addition to specific sandbox options.

Multiple and replication sandboxes, for example, accept a --how\_many\_slaves=X
or --how\_many\_nodes=X option, allowing you to create very large groups.

## SANDBOX HOME

Unless you override the defaults, sandboxes are created inside a 
directory that servers two purposes:

- further isolates the sandboxes, and keep them under easy control if you are in the habit of creating many of them;
- provides a set of handy super-commands, which can be passed to all the sandboxes. Running "$SANDBOX\_HOME/stop\_all" you will stop all servers of all sandboxes, single or groups, below that directory.

# USING A SANDBOX

Change directory to the newly created one 
(default: $SANDBOX\_HOME/msb\_VERSION for single sandboxes)

The sandbox directory of the instance you just created contains
some handy scripts to manage your server easily and in isolation.

- start
- restart
- stop

    "./start", "./restart", and "./stop" do what their name suggests.
    `start` and `restart` accept parameters that are eventually passed to the server. e.g.:

        ./start --skip-innodb

        ./restart --event-scheduler=disabled

- use

    "./use" calls the command line client with the appropriate parameters,

- clear

    "./clear" stops the server and removes everything from the data directory, letting you ready to start from scratch.

- multiple server sandbox

    On a replication sandbox, you have the same commands, with a "\_all"
    suffix, meaning that you propagate the command to all the members.
    Then you have "./m" as a shortcut to use the master, "./s1" and "./s2"
    to access the slaves (and "s3", "s4" ... if you define more).

    In group sandboxes without a master slave relationship (circular replication and multiple sandboxes) the nodes can be accessed by ./n1, ./n2, ./n3, and so on.

    - start\_all
    - restart\_all
    - stop\_all
    - use\_all
    - clear\_all
    - m
    - s1,s2

## Database users

There are 2 database users installed by default:

    +-----------------+-------------+-------------------------------+
    |  user name      | password    | privileges                    |
    +-----------------+-------------+-------------------------------+
    |  root@localhost | msandbox    | all on *.* with grant option  |
    |  msandbox@%     | msandbox    | all on *.*                    |
    |  rsandbox@127.% | rsandbox    | REPLICATION SLAVE             |
    |                 |             | (only replication sandboxes)  |
    +-----------------+-------------+-------------------------------+

## Ports and sockets

Ports are created from the server version.
a 5.1.25 server will use port 5125, unless you override the default.
Replicated and group sandboxes add a delta number to the version
figure, to avoid clashing with single installations. 

(note: ports can be overridden using -P option during install)

    +--------+-----------------------------+
    | port   | socket                      |
    +--------+-----------------------------+
    |  3310  | /tmp/mysql_sandbox3310.sock |
    +--------+-----------------------------+

## Searching for free ports

MySQL Sandbox uses a fairly reasonable system of default ports that 
guarantees the usage of unused ports most of the times. 
If you are creating many sandboxes, however, especially if you want
several sandboxes using the same versions, collisions may happen.
In these cases, you may ask for a port check before installing, thus 
making sure that your sandbox is really not conflicting with anything.

### Single sandbox port checking

The default behavior when asking to install a sandbox over an existing 
one is to abort. If you specify the `--force` option, the old sandbox
will be saved as 'old\_data' and a new one created.
Instead, using the `--check_port` option, MySQL Sandbox searches for the
first available unused port, and uses it. It will also create a non 
conflicting data directory. For example

    make_sandbox 5.0.79
    # creates a sandbox with port 5079 under $SANDBOX_HOME/msb_5_0_79

A further call to the same command will be aborted unless you specify 
either `--force` or `--check_port`.

    make_sandbox 5.0.79 -- --force
    # Creates a sandbox with port 5079 under $SANDBOX_HOME/msb_5_0_79
    # The contents of the previous data directory are saved as 'old_data'.

    make_sandbox 5.0.79 -- --check_port
    # Creates a sandbox with port 5080 under $SANDBOX_HOME/msb_5_0_79_a

    make_sandbox 5.0.79 -- --check_port
    # Creates a sandbox with port 5081 under $SANDBOX_HOME/msb_5_0_79_b

Notice that this option is disabled when you use a group sandbox (replication or multiple). Even if you set NODE\_OPTIONS=--check\_port, it won't be used, because every group sandbox invokes make\_sandbox with the --no\_check\_port option.

### Multiple sandbox port checking

When you create a multiple sandbox (make\_replication\_sandbox, 
make\_multiple\_sandbox, make\_multiple\_custom\_sandbox) the default behavior
is to overwrite the existing sandbox without asking for confirmation. 
The rationale is that a multiple sandbox is definitely more likely to be a 
created only for testing purposes, and overwriting it should not be a problem.
If you want to avoid overwriting, you can specify a different group name
(`--replication_directory` `--group_directory`), but this will use the
same base port number, unless you specify `--check_base_port`.

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

## Environment variables

All programs in the Sandbox suite recognize and use the following variables:

    * HOME the user's home directory; ($HOME)
    * SANDBOX_HOME the place where the sandboxes are going to be built. 
      ($HOME/sandboxes by default)
    * USER the operating system user;
    * PATH the execution path;
    * if SBDEBUG if set, the programs will print debugging messages

In addition to the above, make\_sandbox will use
 \* SANDBOX\_BINARY or BINARY\_BASE 
   the directory containing the installation server binaries
   (default: $HOME/opt/mysql) 

make\_replication\_sandbox will recognize the following
   \* MASTER\_OPTIONS additional options to be passed to the master
   \* SLAVE\_OPTIONS additional options to be passed to each slave
   \* NODE\_OPTIONS additional options to be passed to each node

The latter is also recognized by 
make\_multiple\_custom\_sandbox and make\_multiple\_sandbox 

The test suite, `test_sandbox`, recognizes two environment variables

    * TEST_SANDBOX_HOME, which sets the path where the sandboxes are
      installed, if the default $HOME/test_sb is not suitable. It is used
      when you test the package with 'make test'
    * PRESERVE_TESTS. If set, this variable prevents the removal of test
      sandboxes created by test_sandbox. It is useful to inspect sandboxes
      if a test fails.

## msb - the Sandbox shortcut

When you have many sandboxes, even the simple exercise of typing the path to the appropriate 'use' script can be tedious and seemingly slow.

If saving a few keystrokes is important, you may consider using `msb`, the sandbox shortcut.
You invoke 'msb' with a version number, without dots or underscores. The shortcut script will try its best at finding the right directory.

    $ msb 5135
    # same as calling 
    # $SANDBOX_HOME/msb_5_1_35/use

Every option that you use after the version is passed to the 'use' script.

    $ msb 5135 -e "SELECT VERSION()"
    # same as calling 
    # $SANDBOX_HOME/msb_5_1_35/use -e "SELECT VERSION()"

Prepending a "r" to the version number indicates a replication sandbox. If the directory is found, the script will call the master.

    $ msb r5135
    # same as calling 
    # $SANDBOX_HOME/rsandbox_5_1_35/m

To use a slave, use the corresponding number immediately after the version.

    $ msb r5135 2
    # same as calling 
    # $SANDBOX_HOME/rsandbox_5_1_35/s2

Options for the destination script are added after the node indication.

    $ msb r5135 2 -e "SELECT 1"
    # same as calling 
    # $SANDBOX_HOME/rsandbox_5_1_35/s2 -e "SELECT 1"

Similar to replication, you can call multiple sandboxes, using an 'm' before the version number.

    $ msb m5135
    # same as calling 
    # $SANDBOX_HOME/multi_msb_5_1_35/n1

    $ msb m5135 2
    # same as calling 
    # $SANDBOX_HOME/multi_msb_5_1_35/n2

If your sandbox has a non-standard name and you pass such name instead of a version, the script will attempt to open a single sandbox with that name.

    $ msb testSB
    # same as calling 
    # $SANDBOX_HOME/testSB/use

If the identified sandbox is not active, the script will attempt to start it.

This shortcut script doesn't deal with any sandbox script other than the ones listed in the above examples.

But the msb can do even more. If you invoke it with a dotted version number, the script will run the appropriate make\*sandbox script and then use the sandbox itself.

    $ msb 5.1.35
    # same as calling 
    # make_sandbox 5.1.35 -- --no_confirm
    # and then
    # $SANDBOX_HOME/msb_5_1_35/use

It works for group sandboxes as well.

    $ msb r5.1.35
    # same as calling 
    # make_replication_sandbox 5.1.35 
    # and then
    # $SANDBOX_HOME/rsandbox_5_1_35/m

And finally, it also does What You Expect when using a tarball instead of a version.

    $ msb mysql-5.1.35-YOUR_OS.tar.gz
    # creates and uses a single sandbox from this tarball

    $ msb r mysql-5.1.35-YOUR_OS.tar.gz
    # creates and uses a replication sandbox from this tarball

    $ msb m mysql-5.1.35-YOUR_OS.tar.gz
    # creates and uses a multiple sandbox from this tarball

Using a MySQL server has never been easier.

# Custom commands during installation

Starting with version 3.1.07 the installation of each sandbox supports the execution of shell and SQL commands during the installation.
You can use the following commands:

    ## SQL statements
    * --pre_grants_sql=query : runs 'query' before loading the grants.
    * --pre_grants_file=filename : runs SQL file 'filename' before loading the grants.
    * --post_grants_sql=query : runs 'query' after the loading the grants.
    * --post_grants_file=filename : runs SQL file 'filename' before loading the grants.
    * --load_plugin=plugin[:plugin_file_name] : loads the given plugin
    

The output of the SQL commands is sent to standard output. 
If the option --no\_show was selected, then the the client is called without options. If --no\_show was not selected (default), then the client is called with -t -v, so that the output is shown in table format.

    ## Shell commands
    * --pre_start_exec=command  : runs 'command' after the installation, before the server starts
    * --pre_grants_exec=command : runs 'command' after the server starts, before loading the grants.
    * --post_grants_exec=command : runs 'command' after the loading the grants.

For each shell call, the following variables are filled:

           SANDBOX_DIR   =  sandbox directory;
           BASEDIR       =  base directory for the sandbox binaries
           DB_DATADIR    =  data directory
           MY_CNF        =  configuration file
           DB_PORT       =  database port
           DB_USER       =  database user
           DB_PASSWORD   =  database password
           DB_SOCKET     =  database socket
           MYSQL_VERSION =  MySQL version (e.g. 5.7.12)
           MYSQL_MAJOR   =  Major part of the version (e.g 5)
           MYSQL_MINOR   =  Minor part of the version (e.g 7)
           MYSQL_REV     =  Revision part of the version (e.g 12)
           EXEC_STAGE    =  Stage of the execution (pre_start_exec, pre_grants_exec, post_grants_exec)
    

The order of execution during the installation is the following:

    * server installation (mysql_install_db or mysqld --initialize)
        * pre_start_exec
    * server start
        * pre_grants_exec
        * pre_grants_sql (includes load_plugin calls)
        * pre_grants_file
    * load grants
        * post_grants_exec
        * post_grants_sql
        * post_grants_file

# SBTool the Sandbox helper

The Sandbox Helper, `sbtool`, is a tool that allows administrative operations 
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

## sbtool - Informational options

### sbtool -o info     

Returns configuration options from a Sandbox (if specified) or from all sandboxes 
under $SANDBOX\_HOME (default).
You can use `--search_path` to tell sbtool where to start. 
The return information is formatted as a Perl structure.

### sbtool -o ports

Lists ports used by the Sandbox. Use `--search_path` to tell sbtool where to 
start looking (default is $SANDBOX\_HOME). You can also use the `--format` option
to influence the outcome. Currently supported are only 'text' and 'perl'.
If you add the `--only_used` option, sbtool will return only the ports that are 
currently open.

### sbtool -o range

Finds N consecutive ports not yet used by the Sandbox. 
It uses the same options used with 'ports' and 'info'. Additionally, you can
define the low and high boundaries by means of `--min_range` and `--max_range`.
The size of range to search is 10 ports by default. It can be changed 
with `--range_size`.

## sbtool - modification options

### sbtool -o port

Changes port to an existing Sandbox.
This requires the options `--source_dir` and `--new_port` to complete the task.
If the sandbox is running, it will be stopped.  

### sbtool -o copy

Copies data from one Sandbox to another.
It only works on **single** sandboxes.
It requires the `--source_dir` and `--dest_dir` options to complete the task.
Both Source and destination directory must be already installed sandboxes. If any 
of them is still running, it will be stopped. If both source and destination directory
point to the same directory, the command is not performed.
At the end of the operation, all the data in the source sandbox is copied to
the destination sandbox. Existing files will be overwritten. It is advisable, but not
required, to run a "./clear" command on the destination directory before performing 
this task.

### sbtool -o move

Moves a Sandbox to a different location.
Unlike 'copy', this operation acts on the whole sandbox, and can move both single
and multiple sandboxes.
It requires the `--source_dir` and `--dest_dir` options to complete the task.
If the destination directory already exists, the task is not performed. If the source
sandbox is running, it will be stopped before performing the operation.
After the move, all paths used in the sandbox scripts will be changed.

### sbtool -o tree

Creates a replication tree, with one master, one or more intermediate level slaves,
and one or more leaf node slaves for each intermediate level.
To create the tree, you need to create a multiple nodes sandbox (using `make_multiple_sandbox`)
and then use `sbtool` with the following options:

    * --tree_dir , containing the sandbox to convert to a tree
    * --master_node, containing the node that will be master
    * --mid_nodes, with a list of nodes for the intermediate level
    * --leaf_nodes, with as many lists as how many mid_nodes
      Each list is separated from the next by a pipe sign (|).

Alternatively, you can use the `--tree_nodes` option to describe all
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

### sbtool -o preserve

Makes a sandbox permanent.
It requires the `--source_dir` option to complete the task.
This command changes the 'clear' command within the requested sandbox,
disabling its effects. The sandbox can't be erased using 'clear' or 'clear\_all'.
The 'delete' operation of sbtool will skip a sandbox that has been made permanent.

### sbtool -o unpreserve

Makes a sandbox NOT permanent.
It requires the `--source_dir` option to complete the task.
This command cancels the changes made by a 'preserve' operation, making a sandbox
erasable with the 'clear' command. The 'delete' operation can be performed 
successfully on an unpreserved sandbox.

### sbtool -o delete

Removes a sandbox completely.
It requires the `--source_dir` option to complete the task.
The requested sandbox will be stopped and then deleted completely. 
WARNING! No confirmation is asked!

### sbtool -o plugin

Installs a given plugin into a sandbox.
It requires the `--source_dir` and `--plugin` options to complete the task.
The plugin indicated must be defined in the plugin template file, which is by default installed in `$SANDBOX_HOME`. 
Optionally, you can indicate a different plugin template with the `--plugin_file` option.
By default, sbtool looks for the plugin template file in the sandbox directory that is the target of the installation. If it is not found there, it will look at `$SANDBOX_HOME` before giving up with an error.

#### Plugin template

The Plugin template is a Perl script containing the definition of the templates you want to install.
Each plugin must have at least one target **Server type**, which could be one of _all\_servers_, _master_, or _slave_. It is allowed to have more than one target types in the same plugin. 

Each server type, in turn, must have at least one section named **operation\_sequence**, an array reference containing the list of the actions to perform. Such actions can be regular scripts in each sandbox (start, stop, restart, clear) or one of the following template sections:

- options\_file 

    It is the list of lines to add to an options file, under the `[mysqld]` label.

- sql\_commands 

    It is a list of queries to execute. Every query must have appropriate semicolons as required. If no semicolon are found in the list, no queries are executed.

- startup\_file

    It is a file, named _startup.sql_, to be created under the data directory. It will contain the lines indicated in this section.
    You must remember to add a line 'init-file=startup.sql' to the options\_file section.

# TESTING

## test\_sandbox

The MySQL Sandbox comes with a test suite, called test\_sandbox, which by
default tests single,replicated, multiple, and custom installations of MySQL
version 5.0.77 and 5.1.32.You can override the version being tested by means
of command line options:

    test_sandbox --versions=5.0.67,5.1.30

or you can specify a tarball

    test_sandbox --versions=/path/to/mysql-tarball-5.1.31.tar.gz
    test_sandbox --tarball=/path/to/mysql-tarball-5.1.31.tar.gz

You can also define which tests you want to run:

    test_sandbox --tests=single,replication

## Test isolation

The tests are not performed in the common `$SANDBOX_HOME` directory, but 
on a separate directory, which by default is `$HOME/test_sb`. To avoid 
interferences, before the tests start, the application runs the 
`$SANDBOX_HOME/stop_all` command.
The test directory is considered to exist purely for testing purposes, and
it is erased several times while running the suite. Using this directory 
to store valuable data is higly risky.

## Tests during installation

When you build the package and run 

    make test

test\_sandbox is called, in addition to many other tests in the ./t directory, 
and the tests are performed on a temporary directory under 
`$INSTALLATION_DIRECTORY/t/test_sb`. By default, version 5.6.26 is used.
If this version is not found in `$HOME/opt/mysql/`, the test is skipped.
You can override this option by setting the TEST\_VERSION environment variable.

    TEST_VERSION=5.7.9 make test
    TEST_VERSION=$HOME/opt/mysql/5.7.9 make test
    TEST_VERSION=/path/to/myswl-tarball-5.7.9.tar.gz make test

## User defined tests

Starting with version 2.0.99, you can define your own tests, and run them by

    $ test_sandbox --user_test=file_name

### simplified test script

Inside your test file, you can define test actions.
There are two kind of tests: shell and sql the test type is defined by a keyword followed by a colon.

The 'shell' test requires a 'command', which is passed to a shell.
The 'expected' label is a string that you expect to find within the shell output.
If you don't expect anything, you can just say "expected = OK", meaning that you will
be satisfied with a ZERO exit code reported by the operating system.
The 'msg' is the description of the test that is shown to you when the test runs.

    shell:
    command  = make_sandbox 5.1.30 -- --no_confirm
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
For example, if $SANDBOX\_HOME is /home/sb/tests, the line 

    command  = $SANDBOX_HOME/msb_5_1_30/stop

will expand to:

    command = /home/sb/tests/msb_5_1_30/stop

### Perl based test scripts

In addition to the internal script language, you can also define perl scripts, which will be able to use the $sandbox\_home global variable and to call routines defined inside test\_sandbox. (see list below)
To be identified as a Perl script, the user defined test must have the extension ".sb.pl"

- ok\_shell()

    The `ok_shell` function requires a hash reference containing the following labels:
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

- ok\_sql()  

    The `ok_sql` function requires a hashref containing the following labels:
    A 'path', which is the place where the test engine expects to find a 'use' script.
    The 'query' is passed to the above mentioned script and the output is captured for further processing.
    The 'expected' parameter is a string that you want to find in the query output.
    The 'msg' parameter is like the one used with the ok\_exec function.

- get\_bare\_version()

    This function accepts one parameter, which can be either a MySQL tarball name or a version, and returns the bare version found in the input string.
    If called in list mode, it returns also a normalized version string with dots replaced by underscores.

        my $version = get_bare_version('5.1.30'); 
        # returns '5.1.30'

        my $version = get_bare_version('mysql-5.1.30-OS.tar.gz'); 
        # returns '5.1.30'

        my ($version,$dir_name) = get_bare_version('mysql-5.1.30-OS.tar.gz'); 
        # returns ('5.1.30', '5_1_30')

- ok

    This is a low level function, similar to the one provided by Test::More. You should not need to call this one directly, unless you want to fine tuning a test.

    See the test script t/start\_restart\_arguments.sb.pl as an example

# REQUIREMENTS

To use this package you need at least the following:

- Linux or Mac OSX operating system (it may work in other \*NIX OSs, but has not been tested)
- A binary tarball of MySQL 3.23 or later
- Perl 5.8.1 or later 
- Bash shell

# COPYRIGHT

Version 3.1

Copyright (C) 2006-2018 Giuseppe Maxia

Home Page  https://github.com/datacharmer

# LEGAL NOTICE

    Copyright 2006-2018 Giuseppe Maxia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
