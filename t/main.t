use strict;
use t::test;

use Devel::GlobalPhase;
use B ();

BEGIN { is global_phase, 'START',   'START'   };
CHECK { is global_phase, 'CHECK',   'CHECK'   };
INIT  { is global_phase, 'INIT',    'INIT'    };
      { is global_phase, 'RUN',     'RUN'     };
END   { is global_phase, 'END',     'END'     };
push @{ B::end_av()->object_2svref }, sub
      { is global_phase, 'END',     'END via B' };

our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
