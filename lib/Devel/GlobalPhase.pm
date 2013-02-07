package Devel::GlobalPhase;
use strict;
use warnings;

our $VERSION = '0.002001';
$VERSION = eval $VERSION;

use base 'Exporter';

our @EXPORT = qw(global_phase);

sub import {
    my $class = $_[0];
    for (1..$#_) {
        if ($_[$_] eq '-var') {
            splice @_, $_, 1;
            $class->tie_global_phase;
            return if (@_ == 1);
        }
    }
    goto &Exporter::import;
}

if (defined ${^GLOBAL_PHASE}) {
    eval <<'END_CODE' or die $@;

sub global_phase () {
    return ${^GLOBAL_PHASE};
}

sub tie_global_phase {}

1;
END_CODE
}
else {
    eval <<'END_CODE' or die $@;
use B ();

my $global_phase = 'START';
if (B::main_start()->isa('B::NULL')) {
    # loaded during initial compile
    eval <<'END_EVAL' or die $@;
        CHECK { $global_phase = 'CHECK' }
        # try to install an END block as late as possible so it will run first.
        INIT { eval q(END { $global_phase = 'END' }) }
        # INIT is FIFO so we can force our sub to be first
        unshift @{ B::init_av()->object_2svref }, sub { $global_phase = 'INIT' };
        1;
END_EVAL
}
else {
    # loaded during runtime
    $global_phase = 'RUN';
}
END { $global_phase = 'END' }

sub global_phase () {
    if ($global_phase eq 'START') {
        # we use a CHECK block to set this as well, but we can't force
        # ours to run before other CHECKS
        if (!B::main_root()->isa('B::NULL') && B::main_cv()->DEPTH == 0) {
            $global_phase = 'CHECK';
        }
    }
    elsif ($global_phase ne 'DESTRUCT' && B::main_start()->isa('B::NULL')) {
        $global_phase = 'DESTRUCT';
    }
    elsif ($global_phase eq 'INIT' && B::main_cv()->DEPTH > 0) {
        $global_phase = 'RUN';
    }
    if ($global_phase eq 'RUN') {
        # END blocks are FILO so we can't install one to run first.
        # only way to detect END reliably seems to be by using caller.
        # I hate this but it seems to be the best available option.
        # The top two frames will be an eval and the END block.
        my $i;
        1 while CORE::caller(++$i);
        if ($i > 2) {
            my @top = CORE::caller($i - 1);
            my @next = CORE::caller($i - 2);
            if (
                $top[3] eq '(eval)'
                && $next[3] =~ /::END$/
                && $top[2] == $next[2]
                && $top[1] eq $next[1]
                && $top[0] eq 'main'
                && $next[0] eq 'main'
            ) {
                $global_phase = 'END';
            }
        }
    }

    return $global_phase;
}

sub Tie::GlobalPhase::TIESCALAR { bless \(my $s), $_[0]; }
sub Tie::GlobalPhase::STORE { die "Modification of a read-only value attempted"; }
*Tie::GlobalPhase::FETCH = \&global_phase;
sub Tie::GlobalPhase::DESTROY {
    untie ${^GLOBAL_PHASE};
    *{^GLOBAL_PHASE} = \(global_phase);
}

sub tie_global_phase {
    unless (defined ${^GLOBAL_PHASE}) {
        tie ${^GLOBAL_PHASE}, 'Tie::GlobalPhase';
    }
}

1;
END_CODE
}

1;

__END__

=head1 NAME

Devel::GlobalPhase - Detect perl's global phase on older perls.

=head1 SYNOPSIS

    use Devel::GlobalPhase;
    print global_phase; # RUN

    use Devel::GlobalPhase -var;
    print ${^GLOBAL_PHASE}; # RUN

=head1 DESCRIPTION

This gives access to L<${^GLOBAL_PHASE}|perlvar/${^GLOBAL_PHASE}>
in versions of perl that don't provide it. The built in variable will be
used if it is available.

If all that is needed is detecting global destruction,
L<Devel::GlobalDestruction> should be used instead of this module.

=head1 EXPORTS

=head2 global_phase

Returns the global phase either from C<${^GLOBAL_PHASE}> or by calculating it.

=head1 OPTIONS

=head2 -var

If this option is specified on import, the global variable
C<${^GLOBAL_PHASE}> will be created if it doesn't exist, emulating the
built in variable from newer perls.

=head1 BUGS

There are tricks that can be played with B or XS that would fool this
module for the INIT and END phase.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

Uses some code taken from L<Devel::GlobalDestruction>.

=head1 COPYRIGHT

Copyright (c) 2013 the Devel::GlobalPhase L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
