use strict;
use warnings;
use lib 't/lib';
use MiniTest tests => 4;
use File::Spec;
use IPC::Open3;

local $TODO = "can't prevent possible segfault on perl 5.8.9 to 5.12"
  if "$]" >= 5.008009 && "$]" < 5.014000;

for my $layers ( 0, 3 ) {
  my $pid = open3 my $stdin, my $stdout, undef,
    $^X, (map "-I$_", @INC), 't/segfault.pl', "--layers=$layers"
    or die "can't run t/segfault.pl: $!";

  my $out = do { local $/; <$stdout> };
  $out =~ s/\n+\z//;
  waitpid $pid, 0;
  my $signal = $? & 255;
  my $exit = $? >> 8;
  is $signal, 0, "eval+subgen+exit+END, $layers layers, exitted without signal";
  is $exit, 0, "eval+subgen+exit+END, $layers layers, exitted without error"
    or print "#  found phase $out\n";
}
