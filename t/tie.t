use strict;
use t::test tests => 6;

use Devel::GlobalPhase -var;

BEGIN { is ${^GLOBAL_PHASE}, 'START',   'START'   };
CHECK { is ${^GLOBAL_PHASE}, 'CHECK',   'CHECK'   };
INIT  { is ${^GLOBAL_PHASE}, 'INIT',    'INIT'    };
      { is ${^GLOBAL_PHASE}, 'RUN',     'RUN'     };
END   { is ${^GLOBAL_PHASE}, 'END',     'END'     };
our $global = Test::Scope::Guard->new(sub {
      { is ${^GLOBAL_PHASE}, 'DESTRUCT', 'DESTRUCT' };
      done_testing;
});
