# make sure we load before threads.pm
require Devel::GlobalPhase;

do 't/threads.t' or die $@;
