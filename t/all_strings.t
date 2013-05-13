use strict;

use Test::More qw(no_plan);

use Vcdiff;


sub test_str {
  my ($source, $target) = @_;

  my $delta = Vcdiff::encode_string($source, $target);
  my $target2 = Vcdiff::decode_string($source, $delta);

  is($target2, $target);
}


test_str("abcdef", "abcdef");
test_str("abcdef", "abcDef");
test_str("abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50);
test_str("abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50);
test_str("\x00"x1000000, "\x01"x1000000);
