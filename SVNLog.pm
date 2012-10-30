package SVNLog;
use strict;
use warnings;

sub print_cached_log {
  my ($l) = @_;
  # $l is the revision entries dumped as retrieved from Svn::Log::retrive();

  my $rev_and_date = "r$l->{revision} | $l->{author} | $l->{date} +0800 (Day, DD Mon YYYY) | ? line";
  print "------------------------------------------------------------------------\n";
  print "$rev_and_date\n";
  foreach my $path (sort keys %{$l->{paths}}) {
    print $l->{paths}->{$path}->{action} . " " . $path . "\n";
  }
  print "\n";
  print $l->{message};
  print "------------------------------------------------------------------------\n";
}

sub get_dir_for {
	my ($r) = @_;
	return int($r / 1000);
}

sub get_latest_revision {
  my ($uuid) = @_;
  return `cd $uuid; ls -R|sort -n|tail -1`
}


1;
