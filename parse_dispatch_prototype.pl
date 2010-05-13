#!/usr/bin/perl
use warnings;
use strict;

# What the prototypes mean: http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.4

my @protos = ('4IuIuIuIs', '3IuIu:Iu', '3Qa<Iu:Qa', '3Qc<Iu:Qc', '1Qa:', '6QaIuIuIuIu:Qa', '4IuIuIuIs:', '1Qb:', '1Iu:', '2Qb<[2IuIu]:', '3IuIuIu:', '1:Qb', '4&+#!IuIuIu:Qb', '2Qc:Iu', "1<+[4IuQaIuIu]:", "1:Qb", "2Qb:Is", "2Qc:Iu", "3Qa&+#!CnIu:", "3Qb<Iu:Qb", "4&+#!CnIuIu:Qb", "4&+#!IuIuIu:Qb", "4IuSIu:Qc", "4QcIuIu:Qb", "3Qa<Iu<Iu:", "6QaIuIsIsIuIu:", "4Iu<Iu<Iu:Iu");

for my $prototype (@protos) {
  $prototype = "".$prototype;

  print <<"END";
} else if (strcmp(prototype, "$prototype") == 0) {
END
  
  $prototype =~ s/^(\d+)// or die;
  # The number of elements in the finished array.  Will be 1 greater then the
  # number of arguments to the dispatched-to function if there is a return value.
  # It does not take into account types that (may) require multiple slots.
  my $n_args = $1;
  
  my $in_return;
  
  # http://www.eblong.com/zarf/glk/glk-spec-070_11.html#s.1.4
  my $extra='';
  my @formats;
  my @arguments;
  my $slot = 0;
  while (length $prototype) {
    if (not $extra and $prototype =~ s/^Iu//) {
      push @formats, "%u";
      push @arguments, "arglist[$slot].uint";
      $slot++;
    } elsif ($extra eq 'return' and $prototype =~ s/^Iu//) {
      push @formats, "returning a glui32";
      $extra = '';
      $slot++;
    } elsif ($extra eq 'outref' and $prototype =~ s/^Iu//) {
      push @formats, "outref to a glui32";
      $extra = '';
      $slot++;

    } elsif (not $extra and $prototype =~ s/^Is//) {
      push @formats, "%d";
      push @arguments, "arglist[$slot].sint";
      $slot++;
    } elsif ($extra eq 'return' and $prototype =~ s/^Is//) {
      push @formats, "returning a glsi32";
      $extra = '';
      $slot++;

    } elsif (not $extra and $prototype =~ s/^Qa//) {
      push @formats, "win at %p";
      push @arguments, "arglist[$slot].opaqueref";
      $slot++;
    } elsif ($extra eq 'return' and $prototype =~ s/^Qa//) {
      push @formats, "returning a winid_t";
      $extra = '';
      $slot++;

    } elsif (not $extra and $prototype =~ s/^Qb//) {
      push @formats, "stream at %p";
      push @arguments, "arglist[$slot].opaqueref";
      $slot++;
    } elsif ($extra eq 'return' and $prototype =~ s/^Qb//) {
      push @formats, "returning a strid_t";
      $extra = '';
      $slot++;

    } elsif (not $extra and $prototype =~ s/^S//) {
      push @formats, "%s";
      push @arguments, "arglist[$slot].charstr";
      $slot++;
      
    } elsif (not $extra and $prototype =~ s/&\+#!Iu//) {
      push @formats, "retained, nonnull, array of glui32 at %p for length %u";
      # The first slot is the ptrflag, telling us if it is NULL.  The
      # # (?) means it can't be null, so ignore it.
      $slot++;
      push @arguments, "arglist[$slot].array";
      $slot++;
      push @arguments, "arglist[$slot].uint";
      $slot++;

    } elsif (not $extra and $prototype =~ s/&\+#!Cn//) {
      push @formats, "retained, nonnull, array of char at %p for length %u";
      # The first slot is the ptrflag, telling us if it is NULL.  The
      # # (?) means it can't be null, so ignore it.
      $slot++;
      push @arguments, "arglist[$slot].array";
      $slot++;
      push @arguments, "arglist[$slot].uint";
      $slot++;

    } elsif (not $extra and $prototype =~ s/\[([^\[\]]+)\]//) {
      push @formats, 'some struct stuff here';

    } elsif (not $extra and $prototype =~ s/^Qc//) {
      push @formats, "fileref at %p";
      push @arguments, "arglist[$slot].opaqueref";
      $slot++;
    } elsif ($extra eq 'return' and $prototype =~ s/^Qc//) {
      push @formats, "returning a frefid_t";
      $extra = '';
      $slot++;
    } elsif ($prototype =~ s/^://) {
      $extra = 'return';
    } elsif ($prototype =~ s/^<//) {
      $extra = 'outref';
    } elsif ($prototype =~ s/^\+//) {
      push @formats, "nonnull";
    } else {
      die "Cannot parse prototype further at $prototype, extra = $extra";
    }
  }
  
  my $formats = join(", ", @formats) . '\n';
  my $arguments = join(", ", @arguments);
  print <<"END";
  printf("$formats", $arguments);
END
}

print <<END;
 else {
  printf("unhandled prototype\\n");
}
END
