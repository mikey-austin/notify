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


package Notify::SMS::ProviderEsendex;

use strict;
use warnings;
use base qw(Notify::Provider);

sub send {
    my ($self, $phone_number, $body, $subject) = @_;

    my $data = {
        EsendexUsername   => $self->{username},
        EsendexPassword   => $self->{password},
        EsendexAccount    => $self->{account},
        EsendexOriginator => ($subject ? $subject : $self->{origin}),
        EsendexRecipient  => $phone_number,
        EsendexBody       => $body,
        EsendexPlainText  => "on"
    };

    my $response = $self->make_https_call(
        $self->{host} . $self->{path}, $data);

    if(defined $response and $response =~ /Result=([a-zA-Z0-9_-]*)/) {
        if($1 =~ /OK/) {
            Notify::Logger->write('OK returned from gateway');
            return 1;
        } else {
            Notify::Logger->err("ERR: expected OK, received: $response");
            return 0;
        }
    } else {
        Notify::Logger->err('ERR: error making HTTPS call to gateway');
        return 0;
    }
}

1;
