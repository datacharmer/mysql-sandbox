package MySQL::Sandbox::Recipes;

our $VERSION="2.0.99e";

1;
__END__
=head1 NAME

MySQL::Sandbox::Recipes - Collection of recipes for MySQL Sandbox

=head1 PURPOSE

This package is a collection of HOW-TO brief tutorials and recipes for MySQL Sandbox

This is B<work in progress>. You may see that some of these recipes are still stubs. I am working on them in my free time, but I am definitely going to complete it.

=head1 Installing MySQL::Sandbox

All the recipes here need the MySQL Sandbox 
L<http://launchpad.net/mysql-sandbox>.
Therefore you need to install it, to be able to follow these recipes.
For a general description of the application, see L<MySQL::Sandbox>.
A presentation on this matter is available at Slideshare 
L<http://www.slideshare.net/datacharmer/mysql-sandbox-3>

=head2 the easy way - as root

This is so easy, that it's almost a shame to show it.
Anyway, here goes.

  # cpan MySQL::Sandbox

=head2 the ambitious way - as unprivileged user

It is not difficult, but it requires some steps that depend on your environment.
To simplify the example, let's assume that you are using perl 5.8.8 and you want 
to install in $HOME/usr/local.

=over 3

=item 1 

download MySQL Sandbox tarball from cpan

=item 2 

set the variables that you will need

    mkdir $HOME/usr/local
    export PATH=$HOME/usr/local/bin
    export PERL5LIB=$HOME/usr/local/lib/perl5/site_perl/5.8.8

=item 3 

build and install

    perl Makefile.PL PREFIX=$HOME/usr/local
    make
    make test
    make install

=back

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

    make_sandbox /path/to/mysql-5.1.34-osx10.5-x86.tar.gz --export_binaries

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

  make_sandbox 5.1.34 --sandbox_port=7800 --sandbox_directory=mickeymouse
  # installs on $SANDBOX_HOME/mickeymouse with port 7800

See the next recipe for an automatic way of getting a different port and directory.

=head2 Creating a single sandbox with automatic port checking

  make_sandbox 5.1.34 --check_port

This option will check if port 5134 is used. If it is, it will check the next available port, until it finds a free one. 
In the previous statement context, 'free' means not only 'in use', but also allocated by another sandbox that is currently not running.
If the directory msb_5_1_34 is used, the sandbox is created in msb_5_1_34_a. The application keeps checking for free ports and unused directories until it finds a suitable combination.

=head2 Creating a single sandbox with a specific option file

  make_sandbox 5.1.34 --my_file=large

This option installs the option file template my-large.cnf, which ships with every MySQL release.
Similarly, you can choose 'small' or 'huge' to load the appropriate template.
If you have your favorite option file, you can specify the full path to it

  make_sandbox 5.1.34 --my_file=/path/to/my_smart.cnf

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

  ./stop
  ./send_kill

=head2 Cleaning up a sandbox

  ./clear

=head2 Copying sandbox contents to another

  sbtool -o copy \
    -s /path/to/source/sandbox \
    -d /path/to/destination/sandbox

=head2 Moving a sandbox

  sbtool -o move \
    -s /path/to/source/sandbox \
    -d /path/to/destination/directory


=head2 Changing port to an existing sandbox

  sbtool -o port \
    -s /path/to/source/sandbox \
    --new_port=XXXX

=head2 Removing a sandbox completely

  sbtool -o delete \
    -s /path/to/source/sandbox 

=head2 Making a sandbox permanent

  sbtool -o preserve \
    -s /path/to/source/sandbox 

  sbtool -o unpreserve \
    -s /path/to/source/sandbox 


# TODO

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

  make_replication_sandbox /path/to/tarball 

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

 make_replication_sandbox --circular=4 /path/to/tarball 

=head2 Using a circular sandbox

Same as using a replication sandbox (see above), but there are no 'm' and 's#' scripts. Instead, there are 'n#' scripts, to access node 1 (n1), node 2, (n2) and so on.

=head2 Creating a group of unrelated sandboxes (same version)

  make_multiple_sandbox /path/to/tarball 
  make_multiple_sandbox --how_many_nodes=4 /path/to/tarball 

=head2 Creating a group of unrelated sandboxes (different versions)

  make_multiple_custom_sandbox /path/to/tarball5.1.34 /path/to/tarball5.0.77
  make_multiple_custom_sandbox 5.1.34 5.0.77

=head2 Using a group of sandboxes

Same as using a replication sandbox (see above), but there are no 'm' and 's#' scripts. Instead, there are 'n#' scripts, to access node 1 (n1), node 2, (n2) and so on.

=head2 Creating a group sandbox with port checking

  make_replication_sandbox --check_base_port \
    --sandbox_directory=something_unique /path/to/tarball

  make_multiple_sandbox --check_base_port \
    --sandbox_directory=something_unique /path/to/tarball 

=head2 Creating a group sandbox with a specific option file

  export MASTER_OPTIONS="--my_file=huge"
  export SLAVE_OPTIONS="--my_file=large"
  make_replication_sandbox 5.1.34

  export NODE_OPTIONS="--my_file=large"
  make_replication_sandbox 5.1.34

  export NODE_OPTIONS="--my_file=large"
  make_multiple_sandbox 5.1.34

=head2 Creating a group sandbox from a source directory

=head2 Starting or restarting a group sandbox with temporary options

  ./start_all [options]
  ./restart_all [options]

=head2 Stopping a group sandbox

  ./stop_all
  ./send_kill_all

=head2 Cleaning up a group sandbox

  ./clear_all

=head2 Moving a group sandbox

  sbtool -o move \
    -s /path/to/source/sandbox \
    -d /path/to/destination/directory

=head2 Removing a group sandbox completely

  sbtool -o delete \
    -s /path/to/source/sandbox 

=head2 Making a group sandbox permanent 

  sbtool -o preserve \
    -s /path/to/source/sandbox 

  sbtool -o unpreserve \
    -s /path/to/source/sandbox 


=head1 COPYRIGHT

Version 3.0

Copyright (C) 2006,2007,2008,2009  Giuseppe Maxia

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

