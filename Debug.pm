#
# Open a new x term on fork.
#

sub DB::get_fork_TTY {
    open XT, q[3>&1 xterm -title 'Forked Perl debugger' -e sh -c 'tty 
+1>&3;\ sleep 10000000' |];
    $DB::fork_TTY = <XT>;
    $DB::inhibit_exit = 0;
    chomp $DB::fork_TTY;
}

1;
