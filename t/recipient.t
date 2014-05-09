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


use Test::Simple tests => 7;
use Notify::Recipient;
use Notify::RecipientFactory;
use JSON;

$label = '0412341234';
$recipient = Notify::RecipientFactory::create($label);
ok(ref $recipient eq 'Notify::SMS::Recipient');
ok($recipient->get_label eq $label);

$json = JSON->new->convert_blessed(1)->encode($recipient);
ok($json eq '{"label":"0412341234"}');

$label = 'mikey';
$recipient = Notify::RecipientFactory::create($label);
ok(ref $recipient eq 'Notify::Email::Recipient');
ok($recipient->get_label eq $label);

$label = 'mikey@example.com';
$recipient = Notify::RecipientFactory::create($label);
ok(ref $recipient eq 'Notify::Email::Recipient');
ok($recipient->get_label eq $label);
