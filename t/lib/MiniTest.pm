# We need to do things in all phases without interference, so avoid
# using Test::More and just implement our own simple test routines.
package MiniTest;
use strict;
$|++;

my $had_error;
my $test_num;
my $plan;
BEGIN {
    if ($INC{'threads.pm'}) {
        require threads::shared;
        threads::shared::share(\$had_error);
        threads::shared::share(\$test_num);
        threads::shared::share(\$plan);
    }
}
END { $? = $had_error ? 1 : 0 }

our $TODO;

sub import {
    shift;
    my %args = @_;
    if ($args{tests}) {
        $plan = $args{tests};
        print "1..$plan\n";
    }
    my $caller;
    no strict 'refs';
    *{"${caller}::TODO"} = *TODO;
    *{"${caller}::$_"} = \&{$_}
      for qw(ok is skip done_testing);
}
sub ok ($;$) {
  print "not " if !$_[0];
  print "ok " . ++$test_num;
  print " - $_[1]" if defined $_[1];
  print " # TODO $TODO" if defined $TODO;
  $had_error++ if !$_[0] && !$TODO;
  print "\n";
  !!$_[0]
}
sub is ($$;$) {
  my $pass = $_[0] eq $_[1];
  ok $pass, $_[2];
  if (!$pass) {
    my (undef, $file, $line) = caller;
    my $mess
      = "# Failed test".($_[2] ? " '$_[2]'" : '')."\n"
      . "#   at $file line $line.\n"
      . "#   '$_[0]' ne '$_[1]'\n";
    print { $TODO ? \*STDOUT : \*STDERR } $mess;
  }
  $pass;
}
sub skip ($;$) {
  print "ok " . ++$test_num;
  for (0..($_[2]||0)) {
    print " # $_[1]" if defined $_[1];
    print "\n";
  }
  !!$_[0]
}
sub done_testing () {
  if ($plan) {
    if ($plan != $test_num) {
      require POSIX;
      POSIX::_exit(1);
    }
  }
  else {
    print "1..$test_num\n";
  }

  if ($had_error) {
    require POSIX;
    POSIX::_exit(1);
  }
  else {
    $? = 0;
  }
}

1;
