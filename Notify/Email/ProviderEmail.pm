#!/usr/bin/perl
#
# notify 0.1.1
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


package Notify::Email::ProviderEmail;

use strict;
use warnings;
use Net::SMTP;
use base qw(Notify::Provider);

use constant {
    TIMEOUT => 10
};

sub send {
    my ($self, $to, $body, $subject) = @_;
    
    my $smtp = Net::SMTP->new(
        $self->{host},
        Port => $self->{port},
        Timeout => $self->TIMEOUT);

    if(!$smtp) {
        Notify::Logger->err('Could connect to ' . $self->{host});
        return 0;
    }

    $smtp->auth($self->{username}, $self->{password}) if $self->{auth};
    $smtp->mail($self->{from});
    $smtp->to($to);

    $smtp->data();
    $smtp->datasend("To: $to\n");
    $smtp->datasend('From: ' . $self->{from} . "\n");
    $smtp->datasend("Subject: $subject\n") if defined $subject;
    $smtp->datasend("\n");
    $smtp->datasend($body);
    $smtp->dataend();

    $smtp->quit();

    return 1;
}

1;
