use strict;
use warnings;
use SVN::Log;
$SVN::Log::FORCE_COMMAND_LINE_SVN = 1;
use Data::Dumper;
use File::Slurp;

if (scalar @ARGV == 0) {
  die "Usage: $0 <svnurl> <startrev> [endrev]";
}

my $svnurl = $ARGV[0];
my $startrev = $ARGV[1];
my $endrev = $ARGV[2];

my $uuid = get_repo_uuid($svnurl);
die "Could not get uuid?" if ! defined $uuid;
my $revcache = "revcache-$startrev" . ($endrev ? "-$endrev" : '');

my $revs;
if ( -f $revcache ) {
	$revs = do { no strict 'vars'; eval read_file($revcache); };
} else {
	$revs = SVN::Log::retrieve ($svnurl, $startrev, $endrev);
}

create_or_update_uuid_map($svnurl, $uuid);
foreach my $r (@$revs) {
	my $revision = $r->{revision};
	die "No revision??" if ! defined $revision;
        my $dir = get_dir_for($revision);
	$dir = "$uuid/$dir";
	if (! -d $dir) {
		`mkdir -p $dir`;
	}
	open my $file, '>', "$dir/$revision" or die "Error: $!";
	print $file Dumper($r);
	close $file;
}

# subs
sub get_dir_for {
	my ($r) = @_;
	return int($r / 1000);
}

sub get_repo_uuid {
	my ($svnurl) = @_;
	my @lines = qx{svn info $svnurl};
	if (scalar @lines == 0) {
		die "Error exe svn info $svnurl";
	}
	foreach my $line (@lines) {
		if ($line =~ /^Repository UUID: (.*)/) {
			my $uuid = $1;
			return $uuid;
		}
	}
	return undef;
}

sub create_or_update_uuid_map {
	my ($svnurl, $uuid) = @_;

	my $mapfile = 'url2uuid.txt';
	my $map;
	if (! -f $mapfile) {
		$map = { $uuid => [ $svnurl ] };
	} else {
		$map = do { no strict 'vars'; eval read_file($mapfile); };
		if (! defined $map->{$uuid}) {
			$map->{$uuid} = [ $svnurl ];
		} else {
			foreach my $url (@{$map->{$uuid}}) {
				if ($url eq $svnurl) {
					# It's already recorded. Do nothing;
					return;
				}
			}
			# It's not there yet. Add it.
			push @{$map->{$uuid}}, $svnurl;
		}
	}
	write_file($mapfile, Dumper $map);
}
