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


package Notify::Suspend;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use IO::Socket::UNIX;
use Notify::Logger;

sub new {
    my ($class, $minutes) = @_;
    my $self = {
        _seconds => ($minutes * 60),
    };
    bless $self, $class;
}

sub start {
    my $self = shift;
    my $select = IO::Select->new;

    Notify::Logger->write('Notifications disabled for '
                          . $self->{_seconds} . ' seconds');

    # Clear signals.
    $SIG{'HUP'} = $SIG{'INT'} = $SIG{'TERM'} = sub { exit(0); };

    sleep($self->{_seconds});

    #
    # The parent will clean up after a SIGCHLD is received, so just
    # exit here.
    #
    exit(0);
}

1;
