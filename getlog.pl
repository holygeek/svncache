use strict;
use warnings;
use SVN::Log;
$SVN::Log::FORCE_COMMAND_LINE_SVN = 1;
use Data::Dumper;
use File::Slurp;
use Getopt::Std;
use SVNLog;

my $UUIDMAP = 'url2uuid.txt';

sub usage {
  print <<EOF
DESCRIPTION
  $0 - Retrieve and cache svn logs
SYNOPSIS
  $0 <svnurl> <startrev> [endrev]
  $0 -d
OPTIONS
  -d
    Fetch new log for each existing cached logs
  -n
    Dry run (implies -d).
  -v
    Be verbose.
EOF
}
my %opts;
getopts('dvn', \%opts);
sub verbose {
  my ($text) = @_;
  print "$text\n" if $opts{v} || $opts{n};
}


if (defined $opts{d}) {
  fetch_new_logs();
} else {
  if (scalar @ARGV != 3) {
    usage();
    exit 0;
  }
  my $svnurl = $ARGV[0];
  my $startrev = $ARGV[1];
  my $endrev = $ARGV[2] || 'HEAD';
  die "startrev must be a number" if $startrev !~ /^[0-9]+$/;
  if (defined $endrev) {
    if ($endrev ne 'HEAD') {
      die "endrev must be a number or 'HEAD'" if $endrev !~ /^[0-9]+$/;
    }
  }

  get_log($svnurl, $startrev, $endrev);
}

exit 0;
# subs

sub fetch_new_logs {
  my $map = eval_dump($UUIDMAP);
  while (my ($uuid, $urls) = each %$map) {
    my $last_revision = get_latest_revision($uuid);
    my $next_revision = $last_revision + 1;
    get_log($urls->[0], $next_revision, 'HEAD');
  }
}

sub get_latest_revision {
  my ($uuid) = @_;
  return `cd $uuid; ls -R|sort -n|tail -1`
}

sub get_log {
  my ($svnurl, $startrev, $endrev) = @_;
  verbose "get_log $svnurl $startrev $endrev";
  exit 0 if $opts{n};

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
    my $dir = SVNLog::get_dir_for($revision);
    $dir = "$uuid/$dir";
    if (! -d $dir) {
      `mkdir -p $dir`;
    }
    open my $file, '>', "$dir/$revision" or die "Error: $!";
    print $file Dumper($r);
    close $file;
    verbose "$revision";
  }
  verbose "";
  return 0;
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

	my $map;
	if (! -f $UUIDMAP) {
		$map = { $uuid => [ $svnurl ] };
	} else {
		$map = do { no strict 'vars'; eval read_file($UUIDMAP); };
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
	write_file($UUIDMAP, Dumper $map);
}

sub eval_dump {
  my ($dumpfile) = @_;
  return do { no strict 'vars'; eval read_file($dumpfile); };
}
