use strict;

use Test::More qw(no_plan);

use Vcdiff;

## Since Vcdiff is an abstract loader module, there's not muchto test
## here. See lib/Vcdiff/Test.pm in this distribution for the shared
## test infrastructure that the backend distributions use.

ok(1, 'loaded');
