use strict;
use t::test;

use Devel::GlobalPhase;

BEGIN { is global_phase, 'START',   'START'   };
CHECK { is global_phase, 'CHECK',   'CHECK'   };
INIT  { is global_phase, 'INIT',    'INIT'    };
      { is global_phase, 'RUN',     'RUN'     };
END   { is global_phase, 'END',     'END'     };

our $global = Test::Scope::Guard->new(sub {
      { is global_phase, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
