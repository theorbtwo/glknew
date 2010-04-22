#!/usr/bin/perl
use warnings;
use strict;

my @protos = ('4IuIuIuIs', '3IuIu:Iu', '3Qa<Iu:Qa', '3Qc<Iu:Qc', '1Qa:', '6QaIuIuIuIu:Qa');

for my $prototype (@protos) {
  $prototype = "".$prototype;

  print <<"END";
else if (strcmp(prototype, "$prototype") == 0) {
END
  
  $prototype =~ s/^(\d+)// or die;
  # The number of elements in the finished array.  Will be 1 greater then the
  # number of arguments to the dispatched-to function if there is a return value.
  # It does not take into account types that (may) require multiple slots.
  my $n_args = $1;
  
  my $in_return;
  
  # http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.4
  my $extra='';
  while (length $prototype) {
    if ($prototype =~ s/^Iu//) {
      print qq!printf("$extra%u, ", arglist[slot].uint); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Is//) {
      print qq!printf("$extra%d, ", arglist[slot].sint); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qa//) {
      print qq!printf("${extra}window, "), \n); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qb//) {
      print qq!printf("${extra}stream type %d, ", (struct glk_stream_struct*)(arlist[slot].opaqueref)->type); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qc//) {
      print qq!printf("${extra}fileref, "), \n); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^://) {
      $extra.='return ';
      $in_return = 1;
    } elsif ($prototype =~ s/^<//) {
      $extra.='out ref ';
    } else {
      die "Cannot parse prototype further at $prototype";
    }
  }
  
  print qq<printf("\\n");\n}>;
}
