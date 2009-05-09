#!/usr/bin/perl
use strict;
use warnings;
use CGI::Pretty qw/:standard/;
print html(), 
      h1("MySQL Sandbox wizard"), 
      p( scalar(localtime()));

my @versions = map { s{.*/}{}; $_ }  grep { -d $_ } 
        glob("/Users/gmax/opt/mysql/*");

print start_form,
      'Sandbox type ', 
      radio_group(
            -name => 'Sandbox type',
            -values => ['single', 'replication', 'circular', 'multiple', 'custom'],
            -default =>'single'
      ),
      p(),
      radio_group( 
              -name   => 'versions',
              -values => [@versions],
              -default => undef,
              -columns => 4,
              -linebreak=>'true',
      ),
      submit (-name => 'OK'),
      end_form
      ;

