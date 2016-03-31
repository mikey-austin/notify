#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $VERSION = '0.4';
my $required_mods = {
    'JSON'         => 0,
    'YAML::XS'     => 0,
    'Digest::HMAC' => 0,
};

my $build = Module::Build->new(
    module_name        => 'Notify',
    dist_name          => 'notify',
    dist_abstract      => 'Notification Throttling Daemon',
    dist_version_from  => __FILE__,
    script_files       => {
        'notify'    => 'notify',
        'notifyctl' => 'notifyctl',
    },
);

$build->create_build_script;
