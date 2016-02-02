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


package Notify::Client::Console;

use strict;
use warnings;
use base qw(Notify::Client);

use Data::Dumper;

#
# Output a response based on the context of this client.
#
sub output {
    my ($self, $response) = @_;

    return if not defined $response;

    print_response($response->body);
}


#
# Pretty print the data structure of the response.
#
sub print_response {
    my $response = shift;

    if(ref $response eq 'ARRAY') {
        foreach my $value (@{$response}) {
            print_response($value);
        }

    } elsif(ref $response eq 'HASH') {
        foreach my $key (keys %{$response}) {
            print "$key: ";
            print_response($response->{$key})
        } 

    } else {
        print $response, "\n";
    }
}

1;
