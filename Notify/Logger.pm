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


package Notify::Logger;

use strict;
use warnings;
use POSIX qw(strftime);
use Notify::Config;
use Sys::Syslog qw(:standard :macros);

sub err {
    my ($class, $message) = @_;
    return $class->write($message, 'err');
}

sub debug {
    my ($class, $message) = @_;
    return $class->write($message, 'debug');
}

sub info {
    my ($class, $message) = @_;
    return $class->write($message, 'info');
}

sub write {
    my ($class, $message, $priority) = @_;

    $priority ||= 'warning';

    if(Notify::Config->get('logging_facility') eq 'syslog') {
        # Setup syslog.
        openlog(Notify::Config->get('name'), Notify::Config->get('syslog_options'), 'user');
        syslog($priority, '%s', $message);
        closelog();
    } else {
        # Just log to the console.
        my $timestamp = strftime "%F %T", localtime;
        print "[$timestamp]: $message\n";
    }

    return $message;
}

1;
