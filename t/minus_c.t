use strict;
use t::test;
BEGIN {
  require B;
  B::minus_c();

  ok $^C, "Test properly running under minus-c";
}
use Devel::GlobalPhase;

BEGIN { is global_phase, 'START',   'START'   };
END   { is global_phase, 'END',     'END'     };
BEGIN {
our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
}
