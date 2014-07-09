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


package Notify::SMS::ProviderSMSGlobal;

use strict;
use warnings;
use base qw(Notify::Provider);

sub send {
    my ($self, $phone_number, $body, $subject) = @_;

    my $data = {
        action   => 'sendsms',
        user     => $self->{username},
        password => $self->{password},
        to       => $phone_number,
        from     => ($subject ? $subject : $self->{origin}),
        text     => $body,
    };

    my $response = $self->make_post(
        $self->{host} . $self->{path}, $data);

    if(defined $response and $response =~ /^(OK|ERROR):(.+)$/) {
        if($1 =~ /OK/) {
            $self->write('OK returned from gateway');
            return 1;
        } else {
            $self->err("Expected OK, received $1: $2");
            return 0;
        }
    } else {
        $self->err('An unknown error occured'
                   . (defined $response ? ": $response" : ''));
        return 0;
    }
}

1;
