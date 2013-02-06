BEGIN { require 5.008 }
use strict;
use ExtUtils::MakeMaker;
use Config;

my %WriteMakefileArgs = (
    NAME            => 'Devel::GlobalPhase',
    AUTHOR          => 'Graham Knop <haarg@haarg.org>',
    LICENSE         => 'perl',
    ABSTRACT_FROM   => 'lib/Devel/GlobalPhase.pm',
    VERSION_FROM    => 'lib/Devel/GlobalPhase.pm',
    PREREQ_PM       => {
        $Config{useithreads} ? (threads => 1.07) : (),
    },
    META_MERGE => {
        resources => {
            repository => 'git://github.com/haarg/Devel-GlobalPhase.git',
            homepage => 'http://github.com/haarg/Devel-GlobalPhase',
        },
        requires => {
            perl => 5.008,
        },
        dynamic_config => 0,
    }
);
delete $WriteMakefileArgs{META_MERGE} if ExtUtils::MakeMaker->VERSION < 6.45_01;
delete $WriteMakefileArgs{LICENSE} if ExtUtils::MakeMaker->VERSION < 6.30_01;

WriteMakefile(%WriteMakefileArgs);

