#!/usr/bin/env perl
use open qw(:utf8 :std);
use warnings qw(FATAL utf8);
my $old_argv = '';
my ($saw_0a, $saw_0d, $saw_0d0a);
my $saw_any_0d0a = 0;

sub report {
  my ($path, $saw_0a, $saw_0d, $saw_0d0a) = @_;
  if ($saw_0d0a && $saw_0a != $saw_0d) {
    print STDERR "mixed line endings (CRLF: $saw_0d0a; LF: $saw_0a; CR: $saw_0d): $old_argv\n";
  } elsif ($saw_0a && $saw_0d && $saw_0a != $saw_0d) {
    print STDERR "mixed line endings (LF: $saw_0a; CR: $saw_0d): $old_argv\n";
  }
}

LINE: while (<>) {
  if (m{^diff --git a/.*? b/.*$}) {
    report($old_argv, $saw_0a, $saw_0d, $saw_0d0a) if $old_argv ne '';
    $saw_0a = $saw_0d = $saw_0d0a = 0;
    next;
  } elsif (m{^[+]{3} b/(.*)}) {
    $old_argv = $1;
    next;
  } elsif (/^(?:index |--- |[+]{3} |@@ )/) {
    next;
  }

  if (/\r\n/) {
    ++$saw_0d0a;
    $saw_any_0d0a = 1;
  }
  ++$saw_0d if /\r/;
  ++$saw_0a if /\n/;
}
report($old_argv, $saw_0a, $saw_0d, $saw_0d0a);

if ($saw_any_0d0a) {
  print STDERR "windows line endings present\n";
}
