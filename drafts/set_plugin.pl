#!/usr/bin/perl
use strict;
use warnings;
use MySQL::Sandbox qw(get_option_file_contents);
use Data::Dumper;

my $directory = shift
    or die "directory and plugin_name required\n";
my $plugin = shift
    or die "directory and plugin_name required\n";

add_plugin($directory, $plugin);
# print $ENV{'SANDBOX_HOME'}, "\n";
# add_plugin("$ENV{'SANDBOX_HOME'}/rsandbox_5_1_45", 'innodb');
# add_plugin("$ENV{'SANDBOX_HOME'}/rsandbox_5_5_2", 'semisynch');

sub add_plugin {
    my ($directory, $plugin) = @_;
    unless ( -d $directory ) {
        die "can't find $directory\n";
    }
    if ( exist_all($directory, [qw(start stop restart use clear)]) ) {
        add_plugin_single($directory, $plugin);
    } 
    elsif ( exist_all($directory, [
                    qw(start_all stop_all restart_all use_all clear_all)]) ) {
        add_plugin_multiple($directory, $plugin);
    }
    else {
        die "directory $directory does not seem to be a sandbox\n";
    } 
}

sub get_plugin_conf {
    my ($directory, $plugin, $plugin_conf_file) = @_;
    if ($plugin_conf_file) {
        unless ( -f $plugin_conf_file) {
            die "could not find $plugin_conf_file \n";
        }
    }
    else {
        $plugin_conf_file = "$directory/plugin.conf";
        unless ( -f $plugin_conf_file) {
            $plugin_conf_file = "$ENV{'SANDBOX_HOME'}/plugin.conf";
        }
        unless ( -f $plugin_conf_file) {
            die "could not find plugin.conf "
                . "in $directory or in $ENV{'SANDBOX_HOME'}\n";
        }
    }
    our $plugin_definition;
    open my $FH, '<', $plugin_conf_file
        or die "can't open $plugin_conf_file ($!)\n";
    my $contents ='';
    while (my $line = <$FH>) {
        $contents .= $line;
    }
    close $FH;
    eval $contents;
    if ($@) {
        die "error processing plugin configuration file $plugin_conf_file\n"
        . "$@\n";
    }
    unless (exists $plugin_definition->{$plugin}) {
        die "the required plugin ($plugin) was not found in the "
            . "configuration file ($plugin_conf_file)\n";
    }
    unless (
            ref($plugin_definition->{$plugin}) 
            &&
            (ref( $plugin_definition->{$plugin}) eq 'HASH')) 
    {
        die "the definition of plugin '$plugin' must be a hash ref\n";
    }
    return ($plugin_conf_file, $plugin_definition->{$plugin});
}

sub is_option_set {
    my ($href, $value) = @_;
    my $value1 = $value;
    my $value2 = $value;
    $value1 =~ s/[_-]/-/g; 
    $value2 =~ s/[_-]/_/g; 
    # print "<$value1> <$value2>\n";exit;
    return (defined($href->{$value1}) or defined($href->{$value2})) ; 
}

sub add_plugin_single {
    my ($directory, $plugin, $plugin_conf_file) = @_;
    my $is_slave = 0;
    my $is_master = 0;
    my $options_from_file = get_option_file_contents("$directory/my.sandbox.cnf");
    # print Dumper $options_from_file; 
    #
    # it is a slave if slave related options
    # are found in the options file
    #
    if (($options_from_file->{prompt} =~ /slave/) 
         && 
         is_option_set( $options_from_file, 'report-host')
        )  
    {
        $is_slave =1;
    } 
    # 
    # covers circular replication where a slave can also be a master
    #
    if ($is_slave 
        && 
        is_option_set($options_from_file, 'auto_increment_increment')
        &&
        is_option_set($options_from_file, 'auto_increment_offset') 
        &&
        is_option_set($options_from_file, 'replicate-same-server-id') 
        &&
        is_option_set($options_from_file, 'log-slave-updates') 
        )
    {
        $is_master = 1;
    }
    #
    # The normal case: a master is such when its directory
    # is called *master/ and there is a prompt named "master"
    # something in its options file
    #
    elsif ( ( $directory =~ m{master/?} ) 
            &&
            ( $options_from_file->{prompt} =~ /master/ )
          ) 
    {
        $is_master =1;
    }
    my $plugin_conf;
    # 
    # reads the plugin configuration file
    #
    ($plugin_conf_file, $plugin_conf) = get_plugin_conf(
                $directory, 
                $plugin, 
                $plugin_conf_file);
    # 
    # Looks for plugin libraries inside the options
    #
    my %plugin_libs = ();
    for my $mode (qw(all_servers master slave)) {
        next unless defined $plugin_conf->{$mode};
        for my $item ( 
                qw(operation_sequence options_file sql_commands startup_file )) {
            unless ($plugin_conf->{ $item }) {
                $plugin_conf->{$item} = [];
            }
            unless (ref($plugin_conf->{$item}) eq 'ARRAY') {
                die "$item must be an array ref\n";
            } 
        }
        for my $line ( @{$plugin_conf->{$mode}{options_file}}, 
                   @{$plugin_conf->{$mode}{sql_commands}}) {
            while ( $line =~ /([-\w]+\.so)/g ) {
                $plugin_libs{ $1 }++;
            } 
        } 
    }
    # 
    # looks for the plugin directory
    #
    my $basedir = get_basedir($directory);
    my $plugindir = "$basedir/lib/plugin";
    unless ( -d $plugindir ) {
        $plugindir = "$basedir/lib/mysql/plugin";
        die "could not find $plugindir\n" unless -d $plugindir;
    }
    #
    # makes sure that the plugin libraries 
    # mentioned in the configuration file exist
    #
    for my $lib (keys %plugin_libs) {
        unless ( -f "$plugindir/$lib" ) {
            die "could not find plugin '$lib' in $plugindir\n";
        } 
    }
    # All elements found. Now we can do the deed.
    #
    # Defines which installation modes to use
    #
    my @install_defs = ();
    if  ($plugin_conf->{'all_servers'}) {
        push @install_defs, 'all_servers';
    }
    if ($is_master) {
        push @install_defs, 'master';
    }
    if ($is_slave) {
        push @install_defs, 'slave';
    }
    unless (@install_defs) {
        die     "No installation instructions found\n"
            .   "You must define one or more of "
            .   "'all_servers', 'master', or 'slave'\n";
    }
    #
    # Runs the installation parts
    #
    for my $inst_def (@install_defs) {
        next unless defined $plugin_conf->{$inst_def};
        my $opseq = $plugin_conf->{$inst_def}{operation_sequence};
        # print Dumper $plugin_conf;exit;
        #
        # Makes sure that the plugin configuration
        # contains a sequence of desired operations
        #
        unless ( defined $opseq ) {
            die   "plugin definition in $plugin_conf_file "
                . "($plugin, $inst_def) must "
                . "contain 'operation_sequence'\n"; 
        }
        #
        # Loops through the requested operations
        #
        for my $op (@$opseq) {
            #
            # If it is a script found in the sandbox, run it
            #
            if ( grep { $op eq $_} qw(start stop clear restart) ) {
                my $result = system "$directory/$op";
                die "error executing $op\n" if $result;
            } 
            #
            # Runs an update of the options file
            #
            elsif ( $op eq 'options_file' ) {
                update_options_file(
                        "$directory/my.sandbox.cnf",
                        'mysqld',
                        $plugin_conf->{$inst_def}{'options_file'},
                        $plugindir
                       );
            }
            #
            # Creates a startup file
            #
            elsif ( $op eq 'startup_file' ) {
                fill_startup_file(
                        "$directory/data/startup.sql",
                        $plugin_conf->{$inst_def}{'startup_file'}
                       );

            }
            #
            # Runs a batch of SQL commands
            #
            elsif ( $op eq 'sql_commands' ) {
                run_sql_commands ($directory, 
                        $plugin_conf->{$inst_def}{'sql_commands'}
                        );
            }
            #
            # Nothing else is recognized. 
            #
            else {
                die "unrecognized command $op in operation_sequence\n";
            }
        }
    }
}

sub run_sql_commands {
    my ($directory, $queries) = @_;
    unless ( -x "$directory/use" ) {
        die   "can't execute sql queries in $directory "
            . "('./use' script not found)\n";
    }
    my $tmp_file = "$directory/tmpqueries0";
    while (-f $tmp_file) {
        $tmp_file =~ s/(\d+)$/$1 + 1/e;
    }
    #
    # Creates a temporary files, filled with queries
    #
    open my $FH, '>', $tmp_file
        or die "can't open $tmp_file";
    my $semicolon_found = 0;
    for my $query (@$queries) {
        print $FH $query;
        if ($query =~ /\s*;$/) {
            $semicolon_found =1;
        }
    }
    close $FH;
    if ($semicolon_found) {
        #
        # Runs the queries
        #
        my $result = system "$directory/use -vv -e 'source $tmp_file' ";
        unlink $tmp_file;
        if ($result) {
            die "error running queries\n";
        }
    }
    else {
        unlink $tmp_file;
        die  "Could not find any semicolon in the SQL list.\n"
            . "Please add at least one semicolon at the end of the"
            . " last line\n";
    }
}

sub update_options_file {
    my ( $fname, $section, $contents, $plugindir ) = @_;
    my @old_contents ;
    unless (-f $fname) {
        die "can't find file $fname\n";
    }
    open my $FH, '<', $fname
        or die "can't open $fname\n";
    @old_contents = <$FH>;
    close $FH;
    my $found_section = 0;
    #
    # Checks for the wanted section to be updated
    # And for already existing commands in the options file
    #
    for my $old_line (@old_contents) {
        chomp $old_line;
        if ($old_line =~ /\[$section\]/) {
            $found_section =1;
        }
        for my $new_line (@$contents) {
            chomp $new_line;
            if ($old_line =~ /^\s*(plugin[_-]dir)\s*=\s*(.*)/) {
                my $key = $1;
                my $old_plugindir = $2;
                $old_plugindir =~ s/\s*$//;
                $old_plugindir =~ s/\/$//;
                $plugindir =~ s/\s*$//;
                $plugindir =~ s/\/$//;
                if ($old_plugindir ne $plugindir) {
                    $old_line = "$key = $plugindir";
                }
                $plugindir = undef;
                next;
            } 
            if ($old_line eq $new_line) {
                die "option file already contains the line <$old_line>\n";
            }
        }    
    }
    unless ($found_section) {
        die "could not find section [$section] in $fname\n";
    }
    rename $fname, "$fname.bak"
        or die "could not rename $fname to $fname.bak ($!)\n";
    open $FH, '>', $fname
        or die "can't create $fname\n";
    #
    # If there was no plugin_dir in the old file
    # the we add it to the new options
    #
    if ($plugindir) {
        unshift @$contents, "plugin_dir = $plugindir";
    }
    my $in_wanted_section = 0;
    #
    # Writes the updated options file
    #
    for my $old_line (@old_contents) {
        if ($old_line =~ /^\s*\[$section\]/) {
            $in_wanted_section =1;
        }
        #
        # If a new section starts,
        # the new options are inserted 
        #
        elsif ($old_line =~ /^\s*\[/) {
            if ($in_wanted_section) {
                $in_wanted_section = 0;
                insert_new_options ($FH, $contents);
            }
        }
        print $FH $old_line, "\n";
    }
    #
    # If we reached the end of the file without 
    # new sections, it means that we are still in the 
    # wanted section and we add the new options here.
    if ($in_wanted_section) {
        $in_wanted_section =0;
        insert_new_options($FH, $contents);
    }
    close $FH;
}

sub insert_new_options {
    my ($FH, $contents) = @_;
    print $FH "#\n# Lines added on ", scalar(localtime), "\n#\n";
    for my $nl (@$contents) {
        print $FH $nl, "\n";
    }
    print $FH "#\n# --- END \n#\n";
}

sub fill_startup_file {
    my ( $fname, $contents ) = @_;
    my @old_contents ;
    if (-f $fname) {
        open my $FH, '<', $fname
            or die "can't open $fname\n";
        @old_contents = <$FH>;
        close $FH;
        for my $old_line (@old_contents) {
            chomp $old_line;
            for my $new_line (@$contents) {
                chomp $new_line;
                if ($old_line eq $new_line) {
                    die "startup file already contains the line <$old_line>\n";
                }
            }    
        }
        rename $fname, "$fname.bak"
            or die "could not rename $fname to $fname.bak ($!)\n";
    }
    open my $FH, '>>', $fname
        or die "can't create $fname\n";
    insert_new_options($FH, $contents);
    #print $FH "#\n# Lines added on ", scalar(localtime), "\n#\n";
    #for my $nl (@$contents) {
    #    print $FH $nl, "\n";
    #}
    #print $FH "#\n# --- END \n#\n";
    close $FH;
}

sub add_plugin_multiple {
    my ($directory, $plugin) = @_;
    my @dirs = grep { -d $_ } glob( "$directory/*/" ) ;
    my $result = system "$directory/stop_all";
    die "error running stop_all in $directory\n" if $result;
    for my $dir (@dirs) {
        if ( exist_all($dir, [qw(start stop restart use clear)]) ) {
            print "Installing <$plugin> in <$dir>\n";
            add_plugin_single($dir, $plugin);
        } 
        else {
            print STDERR "WARNING: directory $dir is not a sandbox\n";
        }
    }
}

sub get_basedir {
    my ($dir) = @_;
    unless ( -f "$dir/start" ) {
        die "can't find file 'start' in $dir\n";
    }
    open my $FH, '<', "$dir/start"
        or die "can't open $dir/start ($!)\n";
    my $basedir = undef;
    while ( (!$basedir) && (my $line =<$FH>)) {
        chomp $line;
        if ($line =~ /^BASEDIR=(\S+)/) {
            $basedir = $1;
            $basedir =~ s/^['" ]//;
            $basedir =~ s{['"/ ]+$}{};
        }
    }
    close $FH;
    die "could not find BASEDIR in $dir/start\n" unless $basedir;
    return $basedir;
}

sub exist_all {
    my ($directory, $files) = @_;
    for my $file ( @$files ) {
        unless ( -x "$directory/$file" ) {
            return 0;
        }
    }
    return 1;
}

