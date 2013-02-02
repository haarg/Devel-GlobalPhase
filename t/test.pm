# We need to do things in all phases without interference, so avoid
# using Test::More and just implement our own simple test routines.
use strict;
$|++;
{
  package
    Test::Scope::Guard;
  sub new { my ($class, $code) = @_; bless [$code], $class; }
  sub DESTROY { my $self = shift; $self->[0]->() }
}

my $had_error;
my $test_num;
my $done;
END { $? = $done ? 0 : 1 }
sub ::ok ($;$) {
  $had_error++, print "not " if !$_[0];
  print "ok " . ++$test_num;
  print " - $_[1]" if defined $_[1];
  print "\n";
  !!$_[0]
}
sub ::is ($$;$) {
  my $out = ::ok $_[0] eq $_[1], $_[2]
    or warn "# $_[0] ne $_[1]\n";
  $out;
}
sub ::skip ($;$) {
  print "ok " . ++$test_num;
  for (0..($_[2]||0)) {
    print " # $_[1]" if defined $_[1];
    print "\n";
  }
  !!$_[0]
}
sub ::done_testing () {
  print "1..$test_num\n";
  if ($had_error) {
    require POSIX;
    POSIX::_exit(1);
  }
  else {
    $? = 0;
    $done = 1;
  }
}

1;
