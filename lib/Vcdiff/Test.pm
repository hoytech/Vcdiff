package Vcdiff::Test;

use strict;

use Vcdiff;
use File::Temp qw/ tempfile /;

require Test::More;


sub verify {
  my ($source_arg, $target_arg, $output_arg) = @_;

  my ($source, $target, $delta);

  if (ref $source_arg) {
    $source = tempfile();
    $source->autoflush(1);
    print $source $$source_arg;
  } else {
    $source = $source_arg;
  }

  if (ref $target_arg) {
    $target = tempfile();
    $target->autoflush(1);
    print $target $$target_arg;
  } else {
    $target = $target_arg;
  }

  my ($target2, $target2_fh);

  if ($output_arg) {
    $delta = tempfile();
    $delta->autoflush(1);
    $target2_fh = tempfile();
    $target2_fh->autoflush(1);

    Vcdiff::diff($source, $target, $delta);
    Vcdiff::patch($source, $delta, $target2_fh);

    seek $target2_fh, 0, 0;
    {
      local $/;
      $target2 = <$target2_fh>;
    }
  } else {
    $delta = Vcdiff::diff($source, $target);
    $target2 = Vcdiff::patch($source, $delta);
  }

  if (ref $target_arg) {
    Test::More::is($target2, $$target_arg);
  } else {
    Test::More::is($target2, $target);
  }
}


my $testcases = [
  ["abcdef", "abcdef"],
  ["abcdef", "abcDef"],
  ["abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50],
  ["abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50],
  ["\x00"x1000000, "\x01"x1000000],
];


## Some backends may only support an in memory API so this is split out into its own test routine

sub in_mem {
  foreach my $testcase (@$testcases) {
    verify($testcase->[0], $testcase->[1]);
  }
}


## Try every combination of streaming/in-memory, except for 0 which is the same as the in_mem tests.

sub streaming {
  my $opt = shift;

  foreach my $testcase (@$testcases) {
    for my $i (1..7) {
      my ($t1, $t2, $t3) = ($testcase->[0], $testcase->[1], undef);
      $t1 = \$t1 if $i & 1;
      $t2 = \$t2 if $i & 2;
      $t3 = 1 if $i & 4;

      next if $opt->{skip_streaming_source_tests} && ($i & 1);

      verify($t1, $t2, $t3);
    }
  }
}


1;
