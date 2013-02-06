use strict;
use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}

BEGIN {
  unless (eval { require threads }) {
    print "1..0 # SKIP threads.pm not installed\n";
    exit 0;
  }
  threads->VERSION(1.07);
}

use t::test;
use Devel::GlobalPhase;

      { is global_phase, 'RUN',     'RUN in thread ' . threads->tid };
END   { is global_phase, 'END',     'END in thread ' . threads->tid };
our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'pre-thread global destroy -> DESTRUCT in ' . (threads->tid ? 'thread' : 'main_program') };
      threads->tid or done_testing;
});

{
    package CloneTest;
    sub CLONE
      { ::is ::global_phase, 'RUN',     'CLONE -> RUN in thread ' . threads->tid };
}
our $clonetest = bless {}, 'CloneTest';

threads->create(sub {
eval q[
      { is global_phase, 'RUN',     'RUN in thread' };
END   { is global_phase, 'END',     'END in thread' };
our $global_thread = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'in thread global destroy -> DESTRUCT in thread ' . (threads->tid ? 'thread' : 'main_program') };
});
1; # don't leak guard
];
})->join;

