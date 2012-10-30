use strict;
use warnings;
use File::Slurp;
use SVNLog;

my $uuid = $ARGV[0] or die "No uuid given.";
my $rev_from = $ARGV[1] or die "No revision given.";
my $rev_to   = $ARGV[2] || $rev_from;
if ($rev_to eq 'MAX') {
  $rev_to = SVNLog::get_latest_revision($uuid);
}
if ($rev_from eq 'MAX') {
  $rev_from = SVNLog::get_latest_revision($uuid);
}

foreach my $r ($rev_from..$rev_to) {

  my $dir = SVNLog::get_dir_for($r);
  $dir = "$uuid/$dir";
  my $cached = "$dir/$r";

  if ( ! -f $cached ) {
    print "$0: Revision not cached: $r\n";
    exit 1;
  }

  my $l = do { no strict 'vars'; eval read_file($cached); };

  SVNLog::print_cached_log($l);
}
