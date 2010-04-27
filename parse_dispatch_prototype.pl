#!/usr/bin/perl
use warnings;
use strict;

# What the prototypes mean: http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.4

my @protos = ('4IuIuIuIs', '3IuIu:Iu', '3Qa<Iu:Qa', '3Qc<Iu:Qc', '1Qa:', '6QaIuIuIuIu:Qa', '4IuIuIuIs:', '1Qb:', '1Iu:', '2Qb<[2IuIu]:');
# , '4&+#!IuIuIu:Qb');

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
  my $in_array;
  while (length $prototype) {
    if ($prototype =~ s/^Iu//) {
      print qq!  printf("$extra%u, ", arglist[slot].uint); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Is//) {
      print qq!  printf("$extra%d, ", arglist[slot].sint); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qa//) {
      print qq!  printf("${extra}window %p, ", arglist[slot].opaqueref); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qb//) {
      print qq!  printf("${extra}stream %p type %d, ", arglist[slot].opaqueref, (struct glk_stream_struct*)(arglist[slot].opaqueref)->type); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^Qc//) {
      print qq!  printf("${extra}fileref, "); slot++; argument++;\n!;
      $extra='';
    } elsif ($prototype =~ s/^\[2IuIu\]//) {
      # Square-bracked structs: http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.3.3
      print <<END;
  if (arglist[slot].ptrflag) {
    slot++;
    printf("$extra {");
    printf("%u, ", arglist[slot].uint); slot++;
    printf("%u", arglist[slot].uint); slot++;
    printf("}, ");
    argument++;
  } else {
    slot++;
  }
END
    #} elsif ($prototype =~ s/^\#//) {
    #  $in_array=1;
    #  $extra.='array ';
    } elsif ($prototype =~ s/^!//) {
      $extra.='retained ';
    } elsif ($prototype =~ s/^://) {
      $extra.='return ';
      $in_return = 1;
    } elsif ($prototype =~ s/^<//) {
      $extra.='out ref ';
    } elsif ($prototype =~ s/^\&//) {
      $extra.='io ref ';
    } elsif ($prototype =~ s/^\+//) {
      $extra.='nonnull ';
    } else {
      die "Cannot parse prototype further at $prototype";
    }
  }
  
  print qq<  printf("\\n");\n}>;
}

print <<END;
 else {
  printf("unhandled prototype\\n");
}
END
