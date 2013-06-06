package Vcdiff::Test;

use strict;

use Vcdiff;

require Test::More;


sub test_str {
  my ($source, $target) = @_;

  my $delta = Vcdiff::diff($source, $target);
  my $target2 = Vcdiff::patch($source, $delta);

  Test::More::is($target2, $target);
}


sub in_mem {
  test_str("abcdef", "abcdef");
  test_str("abcdef", "abcDef");
  test_str("abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50);
  test_str("abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50);
  test_str("\x00"x1000000, "\x01"x1000000);
}


1;
