use strict;
use warnings;
use Data::Dumper;
use File::Slurp;
use SVNLog;

my $uuid = $ARGV[0] or die "No uuid given.";
my $r = $ARGV[1] or die "No revision given.";

my $dir = SVNLog::get_dir_for($r);
$dir = "$uuid/$dir";
my $cached = "$dir/$r";

my $l = do { no strict 'vars'; eval read_file($cached); };

SVNLog::print_cached_log($l);
