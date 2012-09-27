use strict;
use warnings;
use Data::Dumper;
use File::Slurp;

my $r = do { no strict 'vars'; eval read_file($ARGV[0]); };
print Dumper $r;
