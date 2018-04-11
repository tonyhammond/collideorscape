#!/home/tony/bin/perl

################################################################################
#                                                                              #
# Copyright (c) 1996 Tony Hammond. All Rights Reserved.                        #
#                                                                              #
# Permission to use, copy, modify, and distribute this software and its        #
# documentation for NON-COMMERCIAL or COMMERCIAL purposes and without fee is   #
# hereby granted provided that this copyright notice appears in all copies.    #
#                                                                              #
################################################################################

$ThisFile = "cs.pl";
$CodeName = "CollideorScape";

################################################################################

$Debug = 0;
push(@INC,"/home/tony/www/cs/cgi-lib");    # for testing

require "library.pl";
require "toolbox.pl";

################################################################################

#%ENV = (
#'QUERY_STRING', 'z=1&a=s&b=w&e=Hen+(I-5)&ctx=3&p=Anna',
#);

GetControl();

################################################################################

# The following routine is the main control: it gets the arguments, sets up the
# globals, and calls up the appropriate action routine.

sub GetControl {

  if ($ENV{"CONTENT_LENGTH"}) {
    GetArgs("POST");
  } elsif ($ENV{"QUERY_STRING"}) {
    GetArgs("QUERY_STRING");
  }

# We're going to be using the random number generator.

  srand();

# These are the submit button actions.

  undef $Update;
  $Update = $Args{"U"};

  $Action = $Args{"a"};
  $Search = 1 if $Args{"a"} eq "p";
  $Quote = 1 if $Args{"a"} eq "q";
  $Range = 1 if $Args{"a"} eq "r";
  $Stats = 1 if $Args{"a"} eq "s";

# Now let's set which book we're working with. An argument "bt" is the book
# title as returned from the search form. If this is not present we look for
# an argument "b" (from which we can derive the book identifier) and default
# as necessary.

  if ($BookTitle = $Args{"bt"}) {
    foreach $Book (@Books) {
      ($Book =~ /^(\S+)\s+\|\s+(\S.*)/) && ($Key = $1), ($Title = $2);
      last if $Title eq $BookTitle;
    }
  }
  else {
    $Key = $BookKeys{"0"} unless $Key = $BookKeys{$Args{"b"}};
  }
  SetBook($Key);

# First thing is to check out the $State variable. If $State is undefined we
# need to post up the form to collect user input. Note that we can set up the
# form for a given book depending on a QUERY_STRING argument.

  $State = $Args{"z"};
  unless ($State) {
    $State = 1;
    $Update = 1;
  }
  $State++;

# Next we set the episode(s) to work with. Note - how do we correlate these
# with the book selected?

  $Episode = $Args{"e"};
  undef($Episode) if $Episode eq "*";
  $EpisodeUser = $Episode;

  $MatchWords = $Args{"mw"} if $Args{"omw"};
  $MatchCase = $Args{"omc"};
  $SoundsLike =  $Args{"osl"};
  $RegExps =  $Args{"ore"};

  $Limit =  $Args{"lmt"} ? $Args{"lmt"} : 1;

  $Line =  $Args{"l"};
  $LineNumbers =  $Args{"oln"} ? $Args{"oln"} : 0;
#  $Context =  $Args{"ctx"} ? $Args{"ctx"} : $Context = int(rand(7)) + 3;
  $Context =  $Args{"ctx"};
  $ContextUser = $Context;
  $Context = int($Context / 2);

  $Pattern = $Args{"p"};
  $Pattern = $PatternDefault unless $Pattern;
  $PatternUser = $Pattern;

# And dispatch!
  if ($Update) { PutForm(); return 1; }
  elsif ($Range) { DoRange(); return 1; }
  elsif ($Quote) { DoQuotes($Line); return 1; }
  elsif ($Search) { DoSearch(); return 1; }
  elsif ($Stats) { DoStats(); return 1; }

}

################################################################################

# Here we give the three main action routines. We'll start with the simplest
# case first: DoQuotes() is called on both directly to produce random quotes,
# or indirectly to expand on the lists produced by DoSearch().

sub DoQuotes {

  local(@Args) = @_;

  @Episodes = keys %Episodes;
#  while ($Episode !~ /^-/) {
#Debug(int(rand($#Episodes)));
    $Episode = $Episodes[int(rand($#Episodes))] unless $Episode;
#  }
#Debug("$Episode");
  CookBook("$Episode");
#Debug("$Episode");
  GetQuotes(@Args);

}

################################################################################

# DoSearch() opens each file in turn and greps a search pattern.

sub DoSearch {

# We start by studying the pattern, preparatory to further work.

  study $Pattern;

# If the pattern contains a <page.line> reference (or reference pair) we
# field the action off onto DoRange(). This is the lazy-man's aqpproach -
# DoRange() would normally be invoked when $Range is set.

  if ($Pattern =~ /^\s*(\d+\.\d+)(\s*-\s*((\d+)(\.\d+)?))?\s*$/) {
    DoRange($1,$3);
    return 1;
  }

# OK, so it's a straight pattern search! Let's first apply those options.

  unless ($RegExps) {
    $Pattern =~ s/(\s+or\s+)/"\|"/eg;       # or
    $Pattern =~ s/(\s+and\s+)/"\.\*"/eg;    # and
    $Pattern =~ s/(\s+not\s+)/""/eg;        # not

    $Pattern =~ y/A-Z/a-z/ unless $MatchCase;    # lowercase

# Here we modify the user-specified pattern according to the options set.

    if ($SoundsLike) {
      $Pattern =~ s/([aeiouy])/"[aeiouy]*"/eg;    # vowel mutate
      $Pattern =~
        s/([b-df-hj-np-tv-xz])(\1)/"$1\[aeiouy\]*$2*"/eg;
        # vowel interpolate between 2-consonant cluster
      $Pattern =~
         s/([b-df-hj-np-tv-xz])([b-df-hj-np-tv-xz])/"$1\[aeiouy\]*$2"/eg;
        # vowel interpolate between 2-consonant cluster
      $Pattern =~
        s/([b-df-hj-np-tv-xz])([b-df-hj-np-tv-xz])/"$1\[aeiouy\]*$2"/eg;
        # vowel interpolate again to catch 2nd pair in 3-consonant cluster
    }

    ($MatchWords eq "a") && $Pattern =~ s/((\w|\[|\]|\*)+)/"\\b$1\\b"/eg;
    ($MatchWords eq "h") && $Pattern =~ s/((\w|\[|\]|\*)+)/"\\b$1"/eg;
    ($MatchWords eq "t") && $Pattern =~ s/((\w|\[|\]|\*)+)/"$1\\b"/eg;

  }

# And now let's do that search.

  GetSearch();

}

################################################################################

# This is where we deal with ranges. As above would normally be called directly
# when $Range is set, but could also come in through the backdoor when a
# <page.line> pattern is detected.

sub DoRange {

  local($Cite0,$Cite1,$Cites) = @_;

  $Range = 1;    # Set if not already set

# $Cite0 is the start <page.line> reference, and $Cite1 the stop <page.line>.

  unless ($Cite0) {
    $Pattern =~ /^\s*(\d+\.\d+)(\s*-\s*((\d+)(\.\d+)?))?\s*$/;
    $Cite0 = $1;
    $Cite1 = $3 ? $3 : $4;
  }

  $Cite0 =~ /(\d+)\.(\d+)/ && ($Page0 = $1, $Line0 = $2);
  $Cite1 =~ /(\d+)(\.(\d+))?/ &&
    ($Page1 = $3 ? $1 : $Page0, $Line1 = $3 ? $3 : $1);
  $Cite1 = "$Page1.$Line1";    # need to rebuild in case page number omitted

  @PageStarts = sort ByNumber values(%PageStarts);
  $PageRef = 0;
  foreach $PageStart (@PageStarts) {
    last if $PageStart > $Page0;
    $PageRef = $PageStart;
  }

  while (($Key,$Value) = each(%PageStarts)) {
    last if $PageRef eq $Value;
  }

  $Cites = "$Cite0,$Cite1";
  CookBook("$Key");
  GetQuotes($Cites);
}


################################################################################

# The DoStats() routine.

sub DoStats {

  if ($Episode) {
#    push(@Files,$Episodes{$Episode});
    push(@Names,$Episode);
  } else {
    @PageStarts = sort ByNumber values(%PageStarts);
    foreach $PageStart (@PageStarts) {
      while (($Key,$Value) = each(%PageStarts)) {
        if ($Value eq $PageStart) {
          next if $Key =~ /^-/;
#          push(@Files,$Episodes{$Key});
          push(@Names,$Key);
        }
      }
    }
  }

# GetStats();

  $MaxEpisodes = @Names;

  foreach $Name (@Names) {

    local($LL,$PP0,$PP1,$RR,$Words);

    $Link = "$ThisFile?z=$State&a=q&b=$BookKey&e=$NameSafe&oln=$LineNumbers";
    CookBook("$Name");

#    foreach $Cite (@Cites) {
#      if ($Cite) {
#         $PP0 = $Cite unless $PP0;
#         $PP1 = $Cite;
#         $LL++;
#     }
#    }

    $RR = $#Cites + 1;

    @Lines = values %Lines;
    foreach $Line (@Lines) {
      $Words += split(/\W*\s+\W*/,$Line);
      $Words-- if $Line =~ /\w-$/;
    }
    $MaxWords += $Words;

#    $MaxLines += $LL;
    $LL = $MaxCites;
    $MaxLines += $MaxCites;
    $MaxRecords += $RR;

    if ($Ruler) {
      @Ruler = PutRuler();
      push(@Stats,@Ruler);
    } else {
      $Ruler = 1;
    }
    push(@Stats,
         "<a href=\"$Link\"><b>$Name<\/b><\/a><br>\n");
    push(@Stats,"Records: $RR<br>\n");
    push(@Stats,"Lines: $LL ($Cite0 - $Cite1)<br>\n");
    push(@Stats,"&nbsp;&nbsp;&nbsp;&nbsp;<i><sub>$Cite0</sub> $Lines{$Cite0}</i><br>\n");
    push(@Stats,"&nbsp;&nbsp;&nbsp;&nbsp;<i><sub>$Cite1</sub> $Lines{$Cite1}</i><br>\n");
    push(@Stats,"Words: $Words<br>\n");
    }

  PutStats();

}

################################################################################

# This routine reads through one of the episode files stripping out any markup.
# Valid lines are maintained in an associative array %Lines indexed by
# <page.line> references. An auxiliary indexed array @Cites is used to store
# the <page.line> references for ready lookup.

sub CookBook {

  local($Episode) = @_;    # Episode name passed as argument
  local($PP,$LL);          # Page and line number counts
  local($RR) = 0;          # Record number in episode file

  undef %Lines;            # Start with a clean slate
  undef @Cites;            # Ditto
  undef $Cite0;            # Ditto
  undef $Cite1;            # Ditto
  undef $MaxCites;         # Ditto

  if ($PageStarts{$Episode} < 1) {
    $PP  = 1;
  }
  else {
    $PP = $PageStarts{$Episode} - 1;
  }

  open(FILE,"$Prefix$Episodes{$Episode}$Suffix");

  while (<FILE>) {

# New Part? Strip markup and increment counter.
    if (m|\/\*Part\*\/|) {
      s|\/\*Part\*\/||;
    }

# New Episode? Strip markup and increment counter.
    if (m|\{\*Episode\*\}|) {
      s|\{\*Episode\*\}||;
    }

# New Page? Strip markup and increment counter.
    if (m|\<\*page\*\>|) {
      s|\<\*page\*\>||;
      $PP++; $LL=1;
    }

# Now put all non-empty lines away into array "@Lines" and in a parallel array
# "@Cites" save the line citation.

    unless (m|^\s*$|) {
#      if (m|^(\s*\(\*(\w\d+)\*\).*)|) {
#        $Lines{"$PP.$2"} = $_;
#        $Cites[$RR] = "$PP.$2";
#      }
#      else {
        $Lines{"$PP.$LL"} = $_;
        $Cites[$RR] = "$PP.$LL";
        $Cite0 = $Cites[$RR] unless $Cite0;
        $Cite1 = $Cites[$RR];
        $LL++;
#      }
      $MaxCites++;
    }
    $RR++;    # increment the record count
  }
  close(FILE);

}

################################################################################

# This is a trivial routine to display the text of a given episode. Each line
# is written verbatim. What about markup?

sub PutText {

  return unless $Episode;

  if ($Episode) {
    push(@Files,$Episodes{$Episode});
    push(@Names,$Episode);
  }

  PutHead("$CodeName - Text");
  print <<"EOT";
Book: <b>$BookTitle</b><br>
Episode: <b>$Episode</b><br>
<hr>
EOT

  foreach $File (@Files) {
    open(FILE,"$Prefix$File$Suffix");
    while (<FILE>) {
      chop;
      print "$_<br>\n";
    }
    close(FILE);
  }
  print <<"EOT";
<hr>
EOT
  PutTail();
}

################################################################################

# The main search routine.

sub GetSearch {

  local($Options);

  $Matched = 0;

  if ($Episode) {
    push(@Files,$Episodes{$Episode});
    push(@Names,$Episode);
  } else {
    @PageStarts = sort ByNumber values(%PageStarts);
    foreach $PageStart (@PageStarts) {
      while (($Key,$Value) = each(%PageStarts)) {
        if ($Value eq $PageStart) {
          next if $Key =~ /^-/;
          push(@Files,$Episodes{$Key});
          push(@Names,$Key);
        }
      }
    }
  }

  $Options .= "&omw=y" if $MatchWords;
  $Options .= "&omc=y" if $MatchCase;
  $Options .= "&ore=y" if $RegExps;
  $Options .= "&osl=y" if $SoundsLike;

$Timing0 = (times)[0];

  foreach $File (@Files) {

    local($LL) = 0;
    local(@Matches,$Test,$Link,$LinkFile,$Name);


    $Name = shift(@Names);
    $Link = "$ThisFile?z=$State&a=q&b=$BookKey&e=$Name&oln=$LineNumbers";
    $Link .= "&ctx=$ContextUser";
    $Link =~ tr/ /+/;

    open(FILE,"$Prefix$File$Suffix");

    while (<FILE>) {
      $_ = $Frag . $_;
      $Test = $MatchCase
              ? s/($Pattern)/<a href=\"$Link&l=:$LL\"><b>$1<\/b><\/a>/go
              : s/($Pattern)/<a href=\"$Link&l=:$LL\"><b>$1<\/b><\/a>/gio;
      if ($Test) {
        if ($Frag) {
#Debug("PreFrag: $PreFrag");
#Debug("Frag: $Frag");
#Debug("Line: $_");
          eval "s/$Frag/$Frag-<br>/";
          if ($LastFrag) {
           eval "s/$LastFrag/$LastFrag-<br>/";
           undef $LastFrag;
          }
          $_ = $PreFrag . $_;
        }
        push(@Matches,$_);
      }
      $LL++;
#      $TT++;

      if (/^(.*)\b(\w+)-$/) {
          $TmpPreFrag = $1;
          $TmpFrag = $2;
        if (($Frag) && (!$TmpPreFrag)) {
          $PreFrag = $TmpPreFrag ? $TmpPreFrag : $PreFrag . $TmpPreFrag;
          $LastFrag = $Frag;
          $Frag = $TmpFrag;
        }
        else {
          $PreFrag = $TmpPreFrag;
          $Frag = $TmpFrag;
        }
      }
      else {
        undef $PreFrag; undef $Frag;
      }
#      Debug("$Frag") if $Frag;

#      $HH++ if /-$/;
    }
    close(FILE);

#Debug("$HH hyphenations in $LL lines ($TT total)!");
    $Matches = @Matches;
    next unless $Matches;
    if ($Ruler) {
      @Ruler = PutRuler();
      push(@Search,@Ruler);
    } else {
      $Ruler = 1;
    }
    ($Matches == 1)
      ? push(@Search,
        "<a href=\"$Link&l=:0\"><b>$Name<\/b><\/a> ($Matches match)\n")
      : push(@Search,
        "<a href=\"$Link&l=:0\"><b>$Name<\/b><\/a> ($Matches matches)\n");
    push(@Search,"\n");
    push(@Search,@Matches);
    $Matched += $Matches;
  }

$Timing1 = (times)[0];
$Timing = sprintf "%.1f cpu s",$Timing1-$Timing0;

  foreach (@Search) {
    s/^(.*)$/$1<br>/g;
  }

 PutSearch();

}

################################################################################

sub PutRuler {

  <<"EOT";
</td><td></td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table border=0 cellpadding=10>
<tr>
<td></td><td>
EOT

}

##################################################

# With GetQuotes() we have the following situations:
#
#   1.  GetQuotes() -> Random
#   2a. GetQuotes(123) -> Search
#   2b. GetQuotes(0) -> Search
#   3.  GetQuotes(123.1[,123.5]) -> Range
#
# If no line number is specified (1) then we are producing a random quotation.
# Otherwise if the arguments are simple numbers (2) then we are expanding on the
# results of a quotation found by GetSearch(), or if the arguments contain a
# period (3) then we are reproducing a range.
#
# Arguments $L0,$L are indexes into the array @Cites which maps line numbers
# into <page>.<line> references, in turn used as keys into the associative array
# %Lines which contains the lines themselves.

sub GetQuotes {

  local(@Args) = @_;    # either start/stop line pair or quote line

  local(@Quotes);       # array to hold quote

   ($_[0] =~ /([\d\.]+)(,([\d\.]+))*/) && ($L0 = $1), ($L1 = $3);

  PutQuotesHead();

RESTART:

  reset 'Q';

# First let's see what we've got.

  unless ($L0) {

    if ($L0 eq "0") {

      $L0 = 0; $L1 = $#Cites;

    }
    else {

# 1. Random. Generate random $L0 index into @Cites.

    $L0 = int(rand($#Cites));

    }
  }
  else {
    unless ($L0 =~ /\./) {

# 2. Direct: Search. We already have our $L0!

    }
    else {

# 3. Direct: Range. Have to run through @Cites to find keys $L0,$L1.

      for $i ($[ .. $#Cites) {
        $LL = $i;
        last if $Cites[$i] eq $L0;
      }
      $L0 = $LL;
      if ($L1) {
        for $i ($[ .. $#Cites) {
           $LL = $i;
          last if $Cites[$i] eq $L1;
        }
        $L1 = $LL;
      }

    }
  }

# Unless we already have a range we need to establish one by setting the limits
# $L0 = $L0 - $Context and $L1 = $L0 + $Context while respecting boundaries.

  unless ($L1) {
    $L1 = $L0;
    if ($Context) {
      for (1 .. $Context) {
        $L0-- if $L0 > 0;
        while ($Cites[$L0] eq "") { $L0-- if ($L0 > 0) }
        $L1++ if $L1 < $#Cites;
        while ($Cites[$L1] eq "") { $L1++ if ($L1 < $#Cites) }
      }
    }
  }

# We now have a range and can pump out the quote.

  for $i ($L0 .. $L1) {
    $LL = $i;
    next if ($Cites[$LL] eq "");
    push(@Quotes,"$Cites[$LL]*$Lines{$Cites[$LL]}\n");
  }
  push(@Quotes,"\n");
  push(@Quotes,"\n$Siglum: $Cites[$L0]-$Cites[$L1]\n");

  PutQuotesBody();
  $Limit--;
  if (($Limit > 0) && (!$Args[0])) {
    $L0 = ""; $L1 = "";
    goto RESTART;
  }
  PutQuotesTail();

}

################################################################################

sub PutSearch {

  local($Options);

  ($MatchWords eq "a") && ($Options = "match words, ");
  ($MatchWords eq "h") && ($Options = "match word heads, ");
  ($MatchWords eq "t") && ($Options = "match word tails, ");
  ($MatchWords eq "")  && ($Options = "don't match words, ");

  $Options .= $MatchCase ? "match case, " : "don't match case, ";
  $Options .= $RegExps ? "reg exps, " : "no reg exps, ";
  $Options .= $SoundsLike ? "sounds like" : "sounds identical";

  PutHead("$CodeName - Search");

  print "Book: <b>$BookTitle";
  print " �- $EpisodeUser" if $EpisodeUser;
  $Debug ? print "</b> ($Timing)<br>\n" : print "</b><br>\n";
  $Debug ? print "Search Pattern: <b>$Pattern</b><br>\n"
         : print "Search Pattern: <b>$PatternUser</b><br>\n";
  print <<"EOT";
Search Options: <b>$Options</b><br>
Matches: <b>$Matched</b><br>
<p>
<center>
<table border width="90%">
<tr>
<td>
<table border=0 cellpadding=10>
<tr>
<td></td><td>
@Search
</td><td></td>
</tr>
</table>
</td>
</tr>
</table>
</center>
<p>
EOT

  PutTail();
}

################################################################################

sub PutStats {

  local($Options);

  $Options .= $MatchWords ? "match words, " : "don't match words, ";
  $Options .= $MatchCase ? "match case, " : "don't match case, ";
  $Options .= $RegExps ? "reg exps, " : "no reg exps, ";
  $Options .= $SoundsLike ? "sounds like" : "sounds identical";

  PutHead("$CodeName - Statistics");

  print "Book: <b>$BookTitle";
  print " - $EpisodeUser" if $EpisodeUser;
  $Debug ? print "</b> ($Timing)<br>\n" : print "</b><br>\n";
  print <<"EOT";
Episodes: <b>$MaxEpisodes</b><br>
Records: <b>$MaxRecords</b><br>
Lines: <b>$MaxLines</b><br>
Words: <b>$MaxWords</b><br>
<p>
<center>
<table border width="90%">
<tr>
<td>
<table border=0 cellpadding=10>
<tr>
<td></td><td>
@Stats
</td><td></td>
</tr>
</table>
</td>
</tr>
</table>
</center>
<p>
EOT

  PutTail();
}

################################################################################

sub PutQuotesHead {

  PutHead("$CodeName - Quotes");
  print <<"EOT";
<center>
EOT

}

sub PutQuotesBody {

  local($Match) = @_;
  local($LL);

 print <<"EOT";
<table border width="90%">
<tr>
<td>
<table border=0 cellpadding=10>
<tr>
<td></td><td>
EOT

  $LL = 0;
  foreach $Line (@Quotes) {
    chop($Line);

    if ($LL == $#Quotes) {
      print "<i>$Line</i><br>\n";
    }
    else {

# Note: the <p> tag is generally interpreted by browsers as a parskip rather
# than a parindent. Kludge for now is to replace leading spaces by &nbsp;'s.
#      print "<p>\n" if $Line =~ /^\w+/;

      $Line =~ s/^([0-9.]+\*)(\s+)/$1&nbsp;&nbsp;&nbsp;&nbsp;/;
      if ($LineNumbers) {
        $Line =~ s/^([0-9.]+)\*/<sub>$1<\/sub>&nbsp;&nbsp;/;
      } else {
        $Line =~ s/^([0-9.]+)\*//;
      }
      print "$Line<br>\n";
      $LL++;
    }
  }

  print <<"EOT";
</td><td></td>
</tr>
</table>
</td>
</tr>
</table>
<p>
EOT

}

sub PutQuotesTail {

  print<<"EOT";
</center>
EOT

  PutTail();
}

################################################################################

sub PutForm {

  PutHead("$CodeName");

  print <<"EOT";
<center>
<table border=2 cellpadding=20>
<tr>
<form method=post action=\"$ThisFile\">
<input type=hidden name=\"z\" value=\"$State\">
<td>
<br>
<b>Search Options:</b>
<dl>
<dt><input type=checkbox checked name=\"omw\" value="y">
Match words
<dd>
<table>
<tr>
<td>
<input type=radio name="mw" value="a" checked>
</td>
<td>
<i>Whole</i>
</td>
</tr>
<tr>
<td>
<input type=radio name="mw" value="h">
</td>
<td>
<i>Head</i>
</td>
<td>
<input type=radio name="mw" value="t">
</td>
<td>
<i>Tail</i>
</td>
</tr>
</table>
<dt><input type=checkbox name=\"omc\" value="y">
Match case<br>
<dt><input type=checkbox name=\"osl\" value="y">
Sounds like<br>
<dt><input type=checkbox name=\"ore\" value="y">
Use regular expressions<br>
</dl>
<p>
<br>
<p>
<b>Quote Options:</b>
<dl>
<dt><input type=checkbox name=\"oln\" value="y" checked>
Show line numbers
</dl>
<dl>
<dt>Context:
<input size=3 name=\"ctx\" value="7">
&nbsp;&nbsp;
Limit:
<input size=3 name=\"lmt\" value="1"><br>
</dl>
</td>
<td>
EOT

  print "<b>Book:</b><br>\n<select name=\"bt\">\n";
  foreach $Book (@Books) {
    ($Book =~ /^(\S+)\s+\|\s+(\S.*)/) && ($Title = $2);
    if ($Title eq $BookTitle) {
      print "<option selected> $Title\n";
    } else {
      print "<option> $Title\n";
    }
  }
  print "</select>\n<p>\n";

  print "<b>Episode:</b><br>\n<select name=\"e\">\n<option selected> *\n";
  @PageStarts = sort ByNumber values(%PageStarts);
  foreach $PageStart (@PageStarts) {
    while (($Key,$Value) = each(%PageStarts)) {
     if ($Value eq $PageStart) {
        print "<option> $Key\n";
      }
    }
  }
  print "</select>\n<p>\n";

  print <<"EOT";
<hr>
<table>
<tr>
<td>
<input type=radio name=\"a\" value=\"p\" checked> Pattern
</td>
<td>
<input type=radio name=\"a\" value=\"q\"> Quote
</td>
<td>
<input type=radio name=\"a\" value=\"s\"> Statistics
</td>
</tr>
<tr>
<td>
<input type=radio name=\"a\" value=\"r\"> Range
</td>
</tr>
</table>
<p>
<input size=30 name=\"p\" value=\"$PatternDefault\" selected>
<p>
<input type=\"submit\" name=\"S\" value=\"Lookup\">
<input type=\"submit\" name=\"U\" value=\"Update\">
<input type=\"reset\">
</td>
</form>
</tr>
</table>
</center>
EOT

  PutTail("$CodeName");

}

################################################################################

sub Debug {

  unless ($Debug) {
    PutHead("$CodeName - Debug");
    print "<hr>\n";

    $Debug = 1;
  }

  print <<"EOT";
String = \"@_"\<br>
EOT

#  PutTail();

}

################################################################################

exit 1;

__END__
