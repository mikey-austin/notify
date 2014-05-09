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


use Test::Simple tests => 11;
use Notify::Message;
use Notify::Notification;
use JSON;

$message = Notify::Message->new(Notify::Message->CMD_NOTIF);
ok(ref $message eq 'Notify::Message');
ok($message->command eq Notify::Message->CMD_NOTIF);

$body = 'test';
$subject = 'test subject';
$r = Notify::RecipientFactory::create('0412341234');
$n = Notify::Notification->new($r, $body, $subject);
$message->{_body} = $n;

#
# Test parsing a message from raw JSON.
#
$json = '{"error":0,"command":"NOTIFICATION","body":{"recipient":{"label":"0412341234"},"body":"test","subject":"test subject"}}';

$message = Notify::Message->parse($json);
ok($message->command eq Notify::Message->CMD_NOTIF);
ok(ref $message->body eq 'Notify::Notification');
ok($message->body->get_body eq $body);
ok($message->body->get_recipient->get_label eq '0412341234');
ok($message->body->get_subject eq $subject);

#
# Test dispatch message parsing.
#
$json = '{"error":0,"body":[{"body":"test","recipient":{"label":"0412341234"}},{"recipient":{"label":"0412341234"},"body":"test"}],"command":"DISPATCH"}';
$message = Notify::Message->parse($json);
ok($message->command eq Notify::Message->CMD_DISPATCH);
ok(ref $message->body eq 'ARRAY');
ok(@{$message->body} == 2);
ok($message->body->[0]->get_body eq $body);
