#!/usr/bin/perl
#
# Copyright (C) 2014  Mikey Austin <mikey@jackiemclean.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


package Notify::Config;

use strict;
use warnings;
use YAML::XS;

use constant {
    NAME     => 'notify',
    VERSION  => '0.4.0',
};

# Singleton instance.
my $instance = undef;

sub new {
    my ($class, $config_file, $defaults) = @_;

    # Return singleton.
    return $instance if defined $instance;

    my $config;
    $defaults ||= [];

    #
    # If no config file is specified, load the first
    # default that exists.
    #
    for(my $i = (defined $config_file ? -1 : 0);
        $i < @{$defaults} and not defined $config;
        $i++)
    {
        $config_file = $defaults->[$i] if $i >= 0;
        eval {
            $config = $class->load_config($config_file);
        };
    }

    die "Could not load any configuration, exiting..."
        if not defined $config;

    my $self = {
        _file   => $config_file,
        _config => $config
    };

    # Set some defaults if these required variables are not set.
    $self->{_config}->{active_email_providers} ||= [];
    $self->{_config}->{active_sms_providers}   ||= [];

    return ($instance = bless $self, $class);
}

#
# Re-load all of the configuration.
#
sub reload {
    my ($class, $config_file, $defaults) = @_;

    $instance = undef;
    $class->new($config_file, $defaults);
}

#
# Recursively load and merge all included configuration.
#
sub load_config {
    my ($class, $base_config) = @_;
    my $parsed = $class->parse_file($base_config);

    my $sub_config;
    if(defined $parsed->{include} and -d $parsed->{include}) {
        #
        # We have a directory, parse each file within.
        #
        opendir(DIR, $parsed->{include})
            or die "Cannot open config directory"
            . $parsed->{include} . ": $!";

        # Only look for .yaml or .conf files.
        my @listing = grep { (/\.(yaml|conf)$/) } readdir(DIR);
        closedir DIR;

        # Merge in each file found.
        foreach my $file (@listing) {
            $sub_config = $class->load_config(
                $parsed->{include} . "/$file");
            $class->merge_config($parsed, $sub_config);
        }
    } elsif(defined $parsed->{include} and -e $parsed->{include}) {
        #
        # We have an individual file.
        #
        $sub_config = $class->load_config($parsed->{include});
        $class->merge_config($parsed, $sub_config);
    }

    return $parsed;
}

#
# Merge the parsed sub-configuration into the parsed
# base configuration.
#
sub merge_config {
    my ($class, $base_config, $sub_config) = @_;

    foreach my $key (keys %{$sub_config}) {
        if($key eq 'providers') {
            # Add in the additional providers.
            foreach my $p (keys %{$sub_config->{providers}}) {
                $base_config->{providers}->{$p} =
                    $sub_config->{providers}->{$p};
            }
        } else {
            # Overwrite all other keys.
            $base_config->{$key} = $sub_config->{$key}
        }
    }
}

sub parse_file {
    my ($class, $file) = @_;
    my %parsed;

    die "Could not open $file..." if not -e $file;

    eval { %parsed = %{YAML::XS::LoadFile($file)}; };
    die "Error parsing $file: $@" if $@;

    return \%parsed;
}

sub get {
    my ($class, $key) = @_;
    my $self = $class->new;
    return $self->{_config}->{$key};
}

sub set {
    my ($class, $key, $value) = @_;
    my $self = $class->new;
    return $self->{_config}->{$key} = $value;
}

sub version {
    shift->VERSION;
}

sub name {
    shift->NAME;
}

1;
