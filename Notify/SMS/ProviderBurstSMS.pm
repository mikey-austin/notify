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


package Notify::SMS::ProviderBurstSMS;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;
use base qw(Notify::Provider);

sub send {
    my ($self, $phone_number, $body, $subject) = @_;

    # Set the credentials.
    my $data = {
        to      => $phone_number,
        from    => ($subject ? $subject : $self->{origin}),
        message => $body,
    };

    my $ua = $self->get_ua;
    my $request = HTTP::Request::Common::POST($self->{host} . $self->{path}, $data);
    $request->authorization_basic($self->{username}, $self->{password});

    # This should return JSON data.
    my $response = $ua->request($request);
    my $content = $response->decoded_content;
    my $decoded = undef;

    eval {
        $decoded = JSON->new->decode($content);
    };

    if($@) {
        $self->err("Could not parse response: $@");
        return 0;
    }

    if($decoded->{error}->{code} eq 'SUCCESS') {
        $self->write('Message sent successfully');
        return 1;
    } else {
        $self->err($content);
        return 0;
    }
}

1;
