package MySQL::Sandbox::Recipes;

our $VERSION="3.0.34";

1;
__END__

=head1 NAME

MySQL::Sandbox::Recipes - A cookbook for MySQL Sandbox

=head1 PURPOSE

This package is a collection of HOW-TO brief tutorials and recipes for MySQL Sandbox

=head1 Installing MySQL::Sandbox

All the recipes here need the MySQL Sandbox 
L<http://launchpad.net/mysql-sandbox>.
Therefore you need to install it, to be able to follow these recipes.
For a general description of the application, see L<MySQL::Sandbox>.
A presentation on this matter is available at Slideshare 
L<http://www.slideshare.net/datacharmer/mysql-sandbox-3>

=head2 the easy way - as root

This is so easy, that I am almost ashamed to show it.
Anyway, here goes.

  $ sudo su -
  # cpan MySQL::Sandbox

=head2 the ambitious way - as unprivileged user

It is not difficult, but it requires some steps that depend on your environment.
To simplify the example, let's assume that you are using perl 5.8.8 and you want 
to install in $HOME/usr/local.

=over 3

=item 1 

Download MySQL Sandbox tarball from cpan

=item 2 

Set the variables that you will need

    mkdir -p $HOME/usr/local
    export PATH=$HOME/usr/local/bin:$PATH
    export PERL5LIB=$HOME/usr/local/lib/perl5/site_perl/5.8.8

=item 3 

Build and install

    perl Makefile.PL PREFIX=$HOME/usr/local
    make
    make test
    make install

=back

It is a bit complex, but you need to do the setup only once. After that, you can use MySQL Sandbox in your user space.

Another solution, which can be habdy if you use a box without Perl and without root access, is to install Perl in your user space, and then you can use CPAN to install any package in your user space.

=head1 SINGLE SERVER RECIPES

=head2 Creating a single sandbox

=over 3

=item 1

Download or build a MySQL server tarball. Its name is something like
   mysql-X.X.X-Your_Operating_System.tar.gz

=item 2

Make the sandbox

    make_sandbox /path/to/mysql-X.X.X-Your_Operating_System.tar.gz

Notice that this command will expand the tarball into a directory C<X.X.X>, located in the same path where tghe tarball is. If you want to expand in a centralized directory, see the next recipe.

If you have already a centralized repository for your binaries (see next recipe), then you can create a sandbox even more easily:

  make_sandbox 5.1.34
  make_replication_sandbox 5.1.34

=back

=head2 Easily creating more sandboxes after the first one

If you want to reuse the same binaries more than once, you can set up
a repository for such binaries, under $SANDBOX_BINARY, which by default
is $HOME/opt/mysql
If you have such a directory, you have two choices. 

=over 3

=item manually

Expand the tarball, and move it under $HOME/opt/mysql (or set $SANDBOX_BINARY to a path that suits you better). Name the directory with the version number. For example:

   cd $HOME/opt/mysql
   gunzip -c /path/to/mysql-5.1.34-osx10.5-x86.tar.gz | tar -xf -
   mv mysql-5.1.34-osx10.5-x86 5.1.34

Now, next time you want to install a sandbox using 5.1.34, all you need to do is say

  make_sandbox 5.1.34

=item automatically

If you want to combine installation and centralization of the binaries in one go, you can:

    make_sandbox --export_binaries /path/to/mysql-5.1.34-osx10.5-x86.tar.gz 

The expanded tarball is copied to the $SANDBOX_BINARY path, and you can refer to the version number only for future installations.

=back

=head2 Using a single sandbox

When you create a sandbox, the last line of the application output tells you where it was created.
If you don't remember where it is, the default location is $HOME/sandboxes/msb_X_X_XX, where X_X_XX is the version number. For example if you have installed 

    make_sandbox 5.1.34

your sandbox is under $HOME/sandboxes/msb_5_1_34.

To use it, move to that directory and invoke the C<./use> script. This script is a shortcut to invoke the mysql command line client, with all the appropriate parameters.

  ./msb_5_1_34/use
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 1
  Server version: 5.1.34 MySQL Community Server (GPL)
  .
  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
  .
  mysql [localhost] {msandbox} ((none)) > 

The default user is 'msandbox' and the password is 'msandbox'. The same password is also used by the 'root' account.

The 'use' script accepts all the additional options and commands that you would use with the mysql client. For example:

  ./use -e 'show schemas'
   +--------------------+
   | Database           |
   +--------------------+
   | information_schema | 
   | mysql              | 
   | test               | 
   +--------------------+

  ./use -N -B -e 'select version()'
  5.1.34

You don't need to be inside the sandbox to use this script. You can invoke it with a relative or absolute path.

    $HOME/sandboxes/msb_5_1_34/use -e 'select version()'
    +-----------+
    | version() |
    +-----------+
    | 5.1.34    | 
    +-----------+

Notice that this script is created when the sandbox is installed. It is heavily customized for that sandbox only, and it is not replaceable by the same script from another sandbox. Even if you move it to another directory, it will still refer to the sandbox in which it was created. See 'moving a sandbox' for a safe way of moving a sandbox with all its scripts to a different directory.

=head2 Creating a single sandbox with user-defined port and directory

When you create a sandbox, you can fine tune the final product by adding options. You can list of all the available options easily:

    low_level_make_sandbox --help

You can pass any of the options listed to C<make_sandbox>. In particular, since we need to change the port and directory, here's the deed:

  make_sandbox 5.1.34
  # installs on $SANDBOX_HOME/msb_5_1_34 with port 5134

  make_sandbox 5.1.34 -- --sandbox_port=7800 --sandbox_directory=mickeymouse
  # installs on $SANDBOX_HOME/mickeymouse with port 7800

See the next recipe for an automatic way of getting a different port and directory.

=head2 Creating a single sandbox with automatic port checking

  make_sandbox 5.1.34 -- --check_port

This option will check if port 5134 is used. If it is, it will check the next available port, until it finds a free one. 
In the previous statement context, 'free' means not only 'in use', but also allocated by another sandbox that is currently not running.
If the directory msb_5_1_34 is used, the sandbox is created in msb_5_1_34_a. The application keeps checking for free ports and unused directories until it finds a suitable combination.
Notice that this option is disabled when you use a group sandbox (replication or multiple). Even if you set NODE_OPTIONS=--check_port, it won't be used, because every group sandbox invokes make_sandbox with the --no_check_port option.

=head2 Creating a single sandbox with a specific option file

  make_sandbox 5.1.34 -- --my_file=large

This option installs the option file template my-large.cnf, which ships with every MySQL release.
Similarly, you can choose 'small' or 'huge' to load the appropriate template.
If you have your favorite option file, you can specify the full path to it

  make_sandbox 5.1.34 -- --my_file=/path/to/my_smart.cnf

In all cases, the sandbox installer skips all the options that are necessary to keep the sandbox isolated and efficient (user, port,socket,datadir,basedir).

=head2 Creating a single sandbox from a source directory

After you have compiled MySQL from source, you can create a sandbox with the new binaries:

  make_sandbox_from_source $PWD single [options]

The options are the same that you can pass to make_sandbox.
This script creates a tarball, and then invokes make_sandbox to finish the job.

=head2 Starting or restarting a single sandbox with temporary options

Every single server sandbox has a 'start' script, which does what the name suggests. Not only that, but you can start a sandbox with additional parameters for the mysqld daemon.

  ./start --key-buffer=3G

The 'restart' script accepts parameters in the same way. While 'start' only works when the sandboxed server is not running, 'restart' makes sure that the server is stopped, and then invokes 'start' with the optional parameters.

=head2 Stopping a sandbox

Inside every single sandbox there are two scripts that can stop a sandbox.

  ./stop

The 'stop' script attempts a clean stop, using mysqladmin. This works most of the time, especially if you are using a GA release.

  ./send_kill

The 'send_kill' script achieve the same result, but with a different path. First, it tries to stop the sandboxed server nicely, by sending a C<kill -15> to the server PID. If this fails, after a reasonable timeout, it sends a deadly C<kill -9> and removes the PID file. This brutal method is not recommended for general usage, but it is sometimes necessary when dealing with servers in early stages of their development.

=head2 Cleaning up a sandbox

  ./clear

The 'clear' script will empty the data directory, trying to clean the system as much as possible. 
If the server is running when you invoke the script, it will issue a C<drop database> query for each schema. It will also truncate the general and slow query log tables, if they exist.
If the server is not running, 'clear' will clean up the data directory as best as it can. Notice however that invoking 'clear' when the server is not running will not remove stored routines and events.
WARNING! No confirmation is asked! The data will be gone in 1 second.

=head2 Copying sandbox contents to another

Using 'sbtool', the Sandbox helper, this task is easy to perform.
You need two sandboxes. This command cannnot copy to an arbitrary directory, but only to an existing sandbox.
The first sandbox is where the data is stored. You need to use the C<--source_dir> option (or C<-s> for short). The second directory, identified with C<--dest_dir>, (or C<-d>) is the place where the data is copied. 
WARNING! the destination data is overwritten!
This command skips binary logs, relay logs, and general logs.

  sbtool -o copy \
    -s /path/to/source/sandbox \
    -d /path/to/destination/sandbox

Some important points to remember:

=over 3

=item *

This command only copies from a single sandbox to another. If you want to copy from a masterto several slaves, you need to run the command multiple times.

=item *

Before copying, this command stops both source and destination sandbox.

=back

=head2 Moving a sandbox

  sbtool -o move \
    -s /path/to/source/sandbox \
    -d /path/to/destination/directory

This command stops the sandbox, moves it to the requested directory, and then changes all the paths in the scripts, to refer to the new directory.

If the destination directory already exists, the command fails.

=head2 Changing port to an existing sandbox

  sbtool -o port \
    -s /path/to/source/sandbox \
    --new_port=XXXX

THis is similar to moving a sandbox, except that the directory is not changed. The sandbox is stopped, and the port changed in all the scripts.

=head2 Removing a sandbox completely

  sbtool -o delete \
    -s /path/to/source/sandbox 

This is a combination of using the 'clear' script and removing the sandbox.
There is a safety check, though. If the sandbox is a permanent one (see next recipe), the operation aborts.
Otherwise, the script calls 'clear' (clear_all if it is a group sandbox) and then removes all the contents. 

WARNING! No confirmation is asked! The data will be gone in 1 second.

=head2 Making a sandbox permanent

MySQL Sandbox has been created with testing in mind. As such, the sandboxes are expendable, and there are some commands to get rid of them easily and quickly.
However, you don't want always to do this.
Sometimes, you need to keep the data for some time, to record it, or to copy it somewhere, or to use it for some similar testing. Whatever the reason, in these cases you don't want your data to disappear accidentally.
The 'preserve' command, part of the sbtool, disables the 'clear' script in your sandbox, to avoid unpleasant "oh no" moments.
Notice that nothing will protect you against hastily typed 'DROP DATABASE' queries! If you really need your data around, make a copy!

  sbtool -o preserve \
    -s /path/to/source/sandbox 

If you change your mind, invoking sbtool with the 'unpreserve' operation, makes the sandbox erasable again.

  sbtool -o unpreserve \
    -s /path/to/source/sandbox 

=head2 Starting and stopping a sandbox when the host server starts

There is no built-in solution for this recipe. Every operating system has its own method to launch applications at start up.
The important point is that probably you don't need it. MySQL Sandbox is a tool for testing, aiming at creating temporary MySQL servers, and as such you should not need to launch a sandbox at start up.
If you really need it, the MySQL manual explain how to launch at startup the main instance of the database.

=head2 Installing a sandbox from already installed binaries

  make_sandbox_from_installed VERSION [options]

This script (introduced in 2.0.99e) creates a repository of symbolic links from already installed binaries, arranging them in a way that the MySQL Sandbox easily recognizes.
You should move to a directory where you want to keep this repository, before invoking this script. For example:

  mkdir -p $HOME/opt/mysql
  cd $HOME/opt/mysql
  make_sandbox_from_installed 5.1.34 --no_confirm

After this call, you can then install sandboxes (single or multiple) with a simple

  make_{replication_|multiple_}sandbox 5.1.34

=head1 MULTIPLE SERVER RECIPES

=head2 Creating a standard replication sandbox

  make_replication_sandbox /path/to/tarball5.1.34.tar.gz 

As easy as making a single sandbox, this command creates a replication system with one master an two slaves.
If you have set the repository under $SANDBOX_BINARY (see L<Easily creating more sandboxes after the first one>), then you can also say

  make_replication_sandbox 5.1.34

If you want a different number of slaves, you can add an option

  make_replication_sandbox --how_many_slaves=5 5.1.34

=head2 Using a replication sandbox

When you create a replication sandbox, the last line of the application output tells you where it was created.
If you don't remember where it is, the default location is $HOME/sandboxes/rsandbox_X_X_XX, where X_X_XX is the version number. For example if you have installed 

    make_replication_sandbox 5.1.34

your sandbox is under $HOME/sandboxes/rsandbox_5_1_34.

To use it, move to that directory and invoke one of these scripts:

  * ./m  for the master
  * ./s1 for the first slave
  * ./s2 for the second slave, s3 for the third one, and so on
  * ./use_all to send a command to the master and all slaves
  * ./check_slaves to see as a quick glance if the slaves are working

All the above scripts are shortcuts to the 'use' script in the appropriate directory.
The 'use' script was described in the section dedicated to single server recipes.

=head2 Creating a circular replication sandbox

To create a circular replication system, you use the same command used for standard replication, but you add an option to indicate that you want a circular topology.

 make_replication_sandbox --circular=4 /path/to/tarball5.1.34.tar.gz

The above command creates a system with 4 nodes, where node 1 is master of 2, node 2 is master of 3, node 3 is master of 4, and node 4, to close the circle, is master of 1.

If you have a binary repository under $SANDBOX_BINARY, you can use the simplified call:

 make_replication_sandbox --circular=4 5.1.34

=head2 Using a circular sandbox

Same as using a replication sandbox (see above), but there are no 'm' and 's#' scripts. Instead, there are 'n#' scripts, to access node 1 (n1), node 2, (n2) and so on.
You may try this:

  $ ./n1 -e 'create table test.t1 (i int)'
  $ ./n3 -e 'insert into test.t1 values (3)'
  $ ./use_all 'select * from test.t1'
  # server: 1: 
  i
  3
  # server: 2: 
  i
  3
  # server: 3: 
  i
  3
  # server: 4: 
  i
  3

=head2 Creating a group of unrelated sandboxes (same version)

  make_multiple_sandbox /path/to/tarball 
  make_multiple_sandbox --how_many_nodes=4 /path/to/tarball 

A group of unrelated sandboxes is a set of three or more servers installed under the same directory.
What is the purpose of this? It is useful whenever you need to play with several servers without being tied by the master/slave relationship.
One possible reason is to try new replication schemes with a clean setup. Or you may want to test the Federated engine.
Another common usage is when you need to test different approaches to the same problem, and you want to compare results quickly. 

=head2 Creating a group of unrelated sandboxes (different versions)

  make_multiple_custom_sandbox /path/to/tarball5.1.34 /path/to/tarball5.0.77
  make_multiple_custom_sandbox 5.1.34 5.0.77 5.4.0

Similar to the previous one, the composite group is a collection of servers of different versions, all under the same directory.
It can be useful when you want to compare some scheme in different versions, and automate the operations as much as possible.

=head2 Using a group of sandboxes

Same as using a replication sandbox (see above), but there are no 'm' and 's#' scripts. Instead, there are 'n#' scripts, to access node 1 (n1), node 2, (n2) and so on.

A group of sandboxes is easily manged with the 'use_all' script.
For example, you may want to pass a SQL instruction to all the servers

  ./use_all 'select something from dbname.tablename where x=1'

Or you want to execute a SQL script for each server

  ./use_all 'source somescript.sql'

The internal organization of the directory makes it easy to do more complex operations with all the servers within the group. For example, if you want to measure the speed of execution of the same statement for each server (assuming that you have different setups for each one), you can create a shell script:

  ./stop_all
  for N in 1 2 3
  do
    echo "processing node $N"
    ./node$N/start --some_mysqld_option=somevalue
    time ./node$N/use -e 'select something_heavy from somedb.sometable'
    ./node$N/stop
  done

=head2 Creating a group sandbox with port checking

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

=head2 Creating a group sandbox with a specific option file

When you create a group sandbox, make_sanbox is invoked several times, with a predefined set of options. You can add options for each node by means of environmental variables.
If you create a replication sandbox, you can set different options for the master and for the slaves:

  export MASTER_OPTIONS="--my_file=huge"
  export SLAVE_OPTIONS="--my_file=large"
  make_replication_sandbox 5.1.34

  export MASTER_OPTIONS="--my_file=/path/to/my.cnf"
  export SLAVE_OPTIONS="--my_file=/path/to/my_other.cnf"
  make_replication_sandbox 5.1.34

If you don't need the distinction, then you can define the same option for all nodes at once:

  export NODE_OPTIONS="--my_file=large"
  make_replication_sandbox 5.1.34

For non-replication group sandboxes (or for circular replication), $NODE_OPTION is the appropriate way of setting options.

  export NODE_OPTIONS="--my_file=large"
  make_multiple_sandbox 5.1.34

=head2 Creating a group sandbox from a source directory

Same as for a single sandbox, but use the 'replication' or 'multiple' keyword when calling the script.

  make_sandbox_from_source $PWD replication [options]
  make_sandbox_from_source $PWD multiple [options]

=head2 Starting or restarting a group sandbox with temporary options

When you want to restart a group of sandboxes with some temporary options, all you need to do is to pass the option to the command line of ./start_all (if the group was not running) or ./restart_all.

  ./start_all --mysqld=mysqld-debug --gdb
  ./restart_all --max-allowed-packet=20M

=head2 Stopping a group sandbox

The natural way of stopping a group of sandboxes is to invoke the C<stop_all> script. This will work as expected most of the time.

  ./stop_all

If you are dealing with a potentially unresponsive server (for example when testing alpha code), then you may use C<send_kill_all>, which will attempt a gentle stop first, and then kill the server brutally, if it does not respond after a predefined timeout of 10 seconds.

  ./send_kill_all

=head2 Cleaning up a group sandbox

To revert a group sandbox to its original state, the quickest way is to call C<clear_all>, which will invoke the C<clear> script in every depending single sandbox.

  ./clear_all

In a replication sandbox, this command will also remove all replication settings. For this reason, C<clear_all> creates a dummy file called C<needs_initialization>, containing the date and time of the cleanup. This is a signal for C<start_all> to initialize the slaves at the next occurrence. No need for the user to do anything special. The sandbox is self healing.

=head2 Moving a group sandbox

This recipe is the same for single and multiple sandboxes. Using the sbtool will move a sandbox in a clean and safe way. All the elements of the sandbox will be changed to adapt to the new location.

  sbtool -o move \
    -s /path/to/source/sandbox \
    -d /path/to/destination/directory

=head2 Removing a group sandbox completely

The sbtool can delete completely any sandbox, either single or multiple.

  sbtool -o delete \
    -s /path/to/source/sandbox 

This operation will fail if the sandbox has been made permanent. (See next recipe).

=head2 Making a group sandbox permanent 

A sandbox is designed to be easy to create and to throw away, because its primary purpose is testing. However, there are cases when you want to keep the contents around for a while, and you therefore want to make sure that the sandbox is not cleaned up or deleted by mistake. C<sbtool> achieves this goal by disabling the C<clear_all> script and the C<clear> script in all depending sandboxes. In this state, also the 'delete' operation fails (see previous recipe).

  sbtool -o preserve \
    -s /path/to/source/sandbox 

When you need to get rid of the sandbox contents quickly, you can 'unpreserve' it, and the clear* scripts will be enabled again.

  sbtool -o unpreserve \
    -s /path/to/source/sandbox 

=head1 Managing sandboxes in groups

=head2 Using more than one SANDBOX_HOME

The default $SANDBOX_HOME is $HOME/sandboxes, which is suitable for most purposes. If your $HOME is not fit for this task (e.g. if it is located in a NFS partition), you may set a different one on the command line or in your shell startup file.

   export SANDBOX_HOME=/my/alternative/directory
   make_sandbox 5.1.34 -- --check_port

The above procedure is also useful when you, for any reasons, want a completely different set of sandboxes for a new batch of tests, and you want to be able to manage all of them at once. To avoid conflicts, you should always use the --check_port option.

=head2 Stopping all sandboxes at once

The $SANDBOX_HOME directory is the place containing all sandboxes, both single and multiple. This allows you to stop all of them at once with a single command.

    $SANDBOX_HOME/stop_all

=head2 Starting all sandboxes at once

Similarly to the previous recipe, you can start all sandboxes at once with a single command.

    $SANDBOX_HOME/start_all

Notice that, if you created two or more sandboxes that use the same port, (create one with port X, stop it, create another with port X), there will be a conflict, and the second sandbox (and subsequent ones) won't start.

=head2 Running the same query on all active sandboxes

This is a quick way of getting a result from every sandbox under $SANDBOX_HOME. The query passed to C<use_all> will be passed to every C<use> or C<use_all> scripts of the depending sandboxes.

    $SANDBOX_HOME/use_all 'select something_cool'

If you want to run several queries from a script, use the C<source> keyword:

    $SANDBOX_HOME/use_all 'source /full/path/to/script.sql'

=head1 Testing with sandboxes

=head2 Running the built-in test suite

Download and expand the MySQL Sandbox package

    perl Makefile.PL
    make
    TEST_VERSION=/path/to/mysql/tarball make test
    # or
    TEST_VERSION=5.1.34 make test

The TEST_VERSION environment variable contains a version or the path to a tarball used by the test suite. If no test version is provided, most of the tests are skipped.
The test suite creates a private SANDBOX_HOME under ./t/test_sb. All the sandboxes needed for the test are executed there. If something goes wrong, that is the place to inspect for clues.

IMPORTANT: When running test_sandbox, either standalone or within the test suite, it will stop all sandboxes inside $SANDBOX_HOME, to prevent conflicts with the sandboxes created during the tests.

=head2 Creating and running your own tests

Look at the ./t directory inside the MySQL Sandbox package (previous recipe).
There are several .sb files, which are good examples of what you can do with the simple testing language.
If this is not enough, you can use Perl itself. There are a few .sb.pl files, which are plugins for test_sandbox.
Once you create your file, you can run it with

  test_sandbox --user_test=your_test.sb

To use a Perl test, name the test with a .sb.pl extension.

  test_sandbox --user_test=your_test.sb.pl

=head1 Remote Sandboxes

=head2 Access sandboxes from other hosts

By default, a MySQL sandbox instance can be accessed by localhost only. This access is regulated by an option, C<--remote_access>, which is set to '127.%', and it is used to create the default users. You can see the resulting instructions in the file 'grants.mysql' inside each sandbox.

 grant all on *.* to msandbox@'127.%' identified by 'msandbox';
 grant all on *.* to msandbox@'localhost' identified by 'msandbox';
 grant SELECT,EXECUTE on *.* to msandbox_ro@'127.%' identified by 'msandbox';
 grant SELECT,EXECUTE on *.* to msandbox_ro@'localhost' identified by 'msandbox';
 grant REPLICATION SLAVE on *.* to rsandbox@'127.%' identified by 'rsandbox';

If you want to access the sandbox remotely, you can change C<--remote_access> to include your specific subnet, or to open it completely

  --remote_access='192.168.1.%'
  --remote_access='%'

Starting with MySQL::Sandbox 3.0.34, you can also define the bind address for your MySQL server. By default it is '127.0.0.1'. It will be changed to '0.0.0.0' if you choose a customized --remote_access. If you change both --remote_access and --bind_address, No adjustment will be made.

=head2 Deploy MySQL sandboxes to many hosts

MySQL Sandbox 3.0.32 and later include a script that lets you deploy a sandbox quickly to several hosts.

 $ deploy_to_remote_sandboxes.sh -h
 Deploy to remote sandboxes.
 Usage: deploy_to_remote_sandboxes.sh [options]
 -h               => help
 -P port          => MySQL port  (15530)
 -d sandbox dir   => sandbox directory name (remote_sb)
 -m version       => MySQL version (5.5.30)
 -l list of nodes =>list of nodes where to deploy
 -t tarball       => MySQL tarball to install remotely (none)
 
 This command takes the list of nodes and installs a MySQL sandbox in each one.
 You must have ssh access to the remote nodes, or this script won't work.


=head1 COPYRIGHT

Version 3.0

Copyright (C) 2006-2013 Giuseppe Maxia

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

