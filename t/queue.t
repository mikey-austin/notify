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


use Test::Simple tests => 5;
use Notify::Notification;
use Notify::Queue;

$q = Notify::Queue->new;
ok($q->get_size == 0);

$r1 = Notify::RecipientFactory::create('0412341234');
$n1 = Notify::Notification->new($r1, 'test');

$r2 = Notify::RecipientFactory::create('0412341235');
$n2 = Notify::Notification->new($r2, 'test');

$q->enqueue($n1);
ok($q->get_size == 1);

$q->enqueue($n2);
ok($q->get_size == 2);

$popped = $q->dequeue;
ok(@{$popped} == 2);

ok($q->get_size == 0);
