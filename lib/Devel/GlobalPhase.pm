package Devel::GlobalPhase;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION = eval $VERSION;

use B ();
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

my $global_phase = 'START';
if (B::main_start()->isa('B::NULL')) {
    # compile time
    eval q[
        CHECK { $global_phase = 'CHECK' }
        # INIT is FIFO so we can force our sub to be first
        INIT { }
        unshift @{ B::init_av()->object_2svref }, sub { $global_phase = 'INIT' };
        1;
    ] or die $@;
}
else {
    $global_phase = 'RUN';
}
END { $global_phase = 'END' }

use Carp ();
sub global_phase () {
    if ($global_phase eq 'START') {
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
        my $depth = 0;
        # checking sub names seems to be the only way to detect END reliably
        while (my $sub = (caller(++$depth))[3]) {
            if ($sub =~ /::END$/) {
                $global_phase = 'END';
                last;
            }
        }
    }

    return $global_phase;
}

sub Tie::GlobalPhase::TIESCALAR { bless \(my $s), $_[0]; }
sub Tie::GlobalPhase::STORE { die "Modification of a read-only value attempted"; }
*Tie::GlobalPhase::FETCH = \&global_phase;

sub tie_global_phase {
    tie ${^GLOBAL_PHASE}, 'Tie::GlobalPhase';
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

Gives you the value L<perlvar/${^GLOBAL_PHASE}> would in perls it
doesn't exist in. The built in variable will be used if it is
available.

If all that is needed is detecting global destruction,
L<Devel::GlobalDestruction> should be used instead of this module.

=head1 EXPORTS

=head2 global_phase

Returns the global phase either from ${^GLOBAL_PHASE} or by calculating it.

=head1 OPTIONS

=head2 -var

If this option is specified on import, the global variable
C<${^GLOBAL_PHASE}> will be created if it doesn't exist, emulating the
built in variable from newer perls.

=head1 BUGS

There are tricks that can be played with B that would fool this module.

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
