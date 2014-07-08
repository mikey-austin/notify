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

sub new {
    my ($class, $config) = @_;
    my $self = $config;
    bless $self, $class;
}

sub make_https_call {
    my ($self, $url, $data) = @_;
    my $ua = LWP::UserAgent->new;

    my $res = $ua->post($url, $data);
    if($res->is_success) {
        return $res->decoded_content;
    } else {
        # Possibly handle error here.
        return undef;
    }
}

1;
