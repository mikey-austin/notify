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


use Test::Simple tests => 6;
use Notify::Notification;
use Notify::RecipientFactory;

$label = '0412341234';
$body = 'test body';
$subject = 'subject';
$recipient = Notify::RecipientFactory::create($label);
$notification = Notify::Notification->new($recipient, $body, $subject);

ok($notification->get_recipient->get_label eq $label);
ok($notification->get_body eq $body);
ok($notification->get_subject eq $subject);

$decoded = {
    recipient => {
        label => $label
    },
    body => $body,
    subject => $subject,
};

$notification = Notify::Notification->create_from_decoded_json($decoded);
ok($notification->get_recipient->get_label eq $label);
ok($notification->get_body eq $body);
ok($notification->get_subject eq $subject);
