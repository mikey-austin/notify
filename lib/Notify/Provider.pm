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


package Notify::Provider;

use strict;
use warnings;
use Notify::Config;
use LWP::UserAgent;
use URI;

sub new {
    my ($class, $config) = @_;
    my $self = $config;
    bless $self, $class;
}

#
# Convenience routines to prefix the provider name to log messages.
#

sub write {
    my ($self, $message) = @_;
    $self->log('write', $message);
}

sub err {
    my ($self, $message) = @_;
    $self->log('err', $message);
}

sub warn {
    my ($self, $message) = @_;
    $self->log('warn', $message);
}

sub log {
    my ($self, $type, $message) = @_;
    my $name = $self->provider_name;
    my $log  = "<$name> $message";

    for($type) {
        /err(or)?/   and do { Notify::Logger->err($log); last; };
        /warn(ing)?/ and do { Notify::Logger->warn($log); last; };

        Notify::Logger->write($log);
    }
}

sub provider_name {
    my $self = shift;

    my $name = ref $self;
    $name =~ s/^(.+::)*Provider//g;

    return $name;
}

#
# Configure and return a LWP UserAgent object.
#
sub get_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    my $proxy = Notify::Config->get('proxy');

    #
    # Set a custom user agent.
    #
    $ua->agent('notify/' . Notify::Config->version);

    #
    # Verify the hostname against a specified CA certificate.
    #
    if($self->{host} =~ /^https/) {
        if($self->{ca}) {
            $ua->ssl_opts(
                verify_hostnames => 1,
                SSL_ca_file      => $self->{ca},
                );
        } elsif($self->{ca_path}) {
            $ua->ssl_opts(
                verify_hostnames => 1,
                SSL_ca_path      => $self->{ca_path}
                );
        } else {
            $ua->ssl_opts(verify_hostnames => 0);
        }
    }

    #
    # Configure the proxy if configured.
    #
    if(defined $proxy and $proxy->{enabled}) {
        foreach my $proto (qw/http https/) {
            $ua->proxy($proto,  $proxy->{$proto}->{host} . '/')
                if defined $proxy->{$proto};
        }
    }

    return $ua;
}

sub make_get {
   my ($self, $url, $data) = @_;
   my $ua = $self->get_ua;

   # Configure get parameters.
   my $uri = URI->new($url);
   $uri->query_form($data);
   my $res = $ua->get($uri->as_string);

   return $self->process_response($res);
}

sub make_post {
    my ($self, $url, $data) = @_;
    my $ua = $self->get_ua;
    my $res = $ua->post($url, $data);

    return $self->process_response($res);
}

sub process_response {
    my ($self, $res) = @_;

    if($res->is_success) {
        return $res->decoded_content;
    } else {
        # Possibly handle error here.
        Notify::Logger->err('<LWP error> ' . $res->base->as_string);
        Notify::Logger->err('<LWP error> ' . $res->status_line);
        return undef;
    }
}

1;
