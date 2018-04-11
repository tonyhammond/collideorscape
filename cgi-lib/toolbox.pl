#!/home/tony/bin/perl

# ===========================================================================
# unescape(): Return the passed URL after replacing all %NN escaped chars
#             with their actual character equivalents.
#
sub unescape
{
    local($url) = @_;

    $url =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C",hex($1))/ge;
    return $url;
}

# ===========================================================================
# escape(): Return the passed string after replacing all characters matching
#           the passed pattern with their %XX hex escape chars.  Note that
#           the caller must be sure not to escape reserved URL characters
#           (e.g. / in pathnames, ':' between address and port, etc.) and thus
#           this routine can only be applied to each URL part separately. E.g.
#
#           $escname = &escape($name,'[\x00-\x20"#%/;<>?\x7F-\xFF]');
#
sub escape
{
    local($str, $pat) = @_;
         
    $str =~ s/($pat)/sprintf("%%%02lx",unpack('C',$1))/ge;
    return($str);
}


################################################################################

# This subroutine gets all the argument name/value pairs passed by either of
# the argument-passing mechanisms ("POST" or "QUERY_STRING") and deposits them 
# into an associative array %Args.

sub GetArgs {

  local($Method) = @_;

# First buffer the input, weeding out any stray nulls

# Question: What is length of read on STDIN? Check code below:
#  read(STDIN, $Buffer, $ENV{'CONTENT_LENGTH'}+1);

SWITCH: {
  if ($Method eq "POST") { 
    if ($Length = $ENV{"CONTENT_LENGTH"}) {
      sysread(STDIN, $Buffer, $Length);
    }
    last SWITCH;
  }
  if ($Method eq "QUERY_STRING") {
    $Buffer = $ENV{"QUERY_STRING"};
    last SWITCH;
  }
}


# Uncomment for debugging purposes
# print "$Buffer\n";

  @Args = split(/&/, $Buffer);	# Split the name-value pairs

  foreach $Arg (@Args)
  {
      ($ArgNam, $ArgVal) = split(/=/, $Arg);

# Un-Webify plus signs and %-encoding
    $ArgVal =~ tr/+/ /;
    $ArgVal =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

# Stop people from using subshells to execute commands
# Not a big deal when using sendmail, but very important
# when using UCB mail (aka mailx).
#   $ArgVal =~ s/~!/ ~!/g; 

# Uncomment for debugging purposes
#   print "Setting $ArgNam to \"$ArgVal\"<p>";

    $Args{$ArgNam} = $ArgVal;
  }

}
################################################################################

# These next two subroutines provide a means of presenting a uniform page style
# for the output HTML pages.
 
sub PutHead {
  
  local($TitleString,$Date,@Date) = @_;

  require "ctime.pl";

  @Date = split(" ",&ctime(time));
  $Date = "$Date[1] $Date[2], $Date[4] ($Date[3])";

  $Eol = "\015\012"; # Give CRLF terminated headers
  $Header = 1; # Do things by the book
 
  if ($Header) {
    print "HTTP/1.0 200 OK$Eol";
    print "Server: MacHTTP/2.0$Eol";
    print "MIME-Version: 1.0$Eol";
  }
  print "Content-Type: text/html$Eol$Eol";

  print <<"EOT";
<!doctype html public "-//IETF//DTD HTML 3.0//EN">
<html>
<!--
  Copyright (c) 1996 Tony Hammond. All Rights Reserved.

  Permission to use, copy, modify, and distribute this software and its
  documentation for NON-COMMERCIAL or COMMERCIAL purposes and without fee is 
  hereby granted provided that this copyright notice appears in all copies.
-->
<head>
<meta name="author" content="Tony Hammond">
<meta name="mailto" content="hammond\@dial.pipex.com">
<meta name="rights" content="Copyright (c) 1996 Tony Hammond.">
<meta name="idents" content="$TitleString">
<meta name="create" content="$Date">
<title>
$TitleString
</title>
</head>

<body bgcolor="#778899"
      text="#FFFFFF" link="#FFFFFF" alink="#FFFFFF" vlink="#FFFFFF">
<br>
<h1>
$TitleString
</h1>
EOT

}


sub PutTail {
  
  print <<"EOT";
<p>
<address>
<b>
<a href="mailto:hammond\@dial.pipex.com">hammond\@dial.pipex.com</a>
</b>
</body>
</html>
EOT

}

################################################################################

# This routine is for numerical sorts.

sub ByNumber {
  abs $a <=> abs $b;
}

################################################################################

1;

__END__





