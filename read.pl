use strict;
use warnings;
use File::Slurp;
use SVNLog;

my $uuid = $ARGV[0] or die "No uuid given.";
my $rev_from = $ARGV[1] or die "No revision given.";
my $rev_to   = $ARGV[2] || $rev_from;

#print "A $rev_from $rev_to\n";
foreach my $r ($rev_from..$rev_to) {
  my $dir = SVNLog::get_dir_for($rev_from);
  $dir = "$uuid/$dir";
  my $cached = "$dir/$rev_from";

  if ( ! -f $cached ) {
    print "$0: Revision not cached: $rev_from\n";
    exit 1;
  }

  my $l = do { no strict 'vars'; eval read_file($cached); };

  SVNLog::print_cached_log($l);
}
#print "B\n";
