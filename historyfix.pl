#!/usr/bin/perl

my @filenames = ();

if ($ARGV[0] eq "") {
  my $files = `find . -name HISTORY`;
  @filenames = split(/\n/,$files);
} else {
  @filenames = @ARGV;
}

open(FILE, ">/tmp/historyfix.p4edit");
print FILE "p4 edit";
close(FILE);

for $filename (@filenames) {

  $filename =~ s/^\.\///;

  open(FILE, "<$filename");
  $/ = undef;
  my $file = <FILE>;
  close(FILE);
  my $oldfile = $file;
  $file .= "\n\n\n\n";
  $file =~ s/        /\t/gm;
  $file =~ s/^.([ \t])/\t$1/gm;
  $file =~ s/^\*+$//gm;
  $file =~ s/\n\n([ \t])/\n \n$1/gs;
  $file =~ s/^\!200/200/gm;
  $file =~ s/([^\n\t ])\n200/$1\n \n200/gs;
  $file =~ s/\n200/\n\n200/gs;
  #$file =~ s/\n200([^\n])\n([^ \t]+)\n/\n \n200$1\n \n$2\n/gs;
  $file =~ s/^200([0-9]-[0-9]+-[0-9]+[ \t]+)\?([ \t]*)/200$1Anonymous$2/gm;
  $file =~ s/^200([^@\n]+)$/200$1 <anonymous\@sourcemage.org>/mg;
  $file =~ s/^200([0-9])[^0-9]?([0-9][0-9])[^0-9]?([0-9][0-9])/200$1-$2-$3/gm;
  #$file =~ s/^200(.*)\<?([^\t\< ]+\@[^\n\t \>]+)\>?(.*)$/"200" .
  &fixname($1) . "$3 <$2>"/gme; # blah
  $file =~ s/^200([^\n]*) \<?([^\t\< \n]+\@[^\n\t\>]+)\>?([^\n]*)$/"200" . &fixname($1) . "$3 <$2>"/gme; # blah
  $file =~ s/[ \t]+/ /mg;
	$file =~ s/^200([0-9]-[0-9]+-[0-9]+) (\<[^>\n]*\>) ?$/200$1 Anonymous $2/gm;
  $file =~ s/([-0-9 ]+?)[\t ]+([^ ][^\n]*[^ ])[\t ]+(\<[^\n]*\>)[\t ]*\n(.*?)\n\n(?:\n+|)/"$1 $2 $3\n" . &fixit($4) . "\n\n"/sge;
	$file =~ s/^([-0-9 ]+?)[\t ]+([^ ].*[^ ])[\t ]+(\<.*\>)[\t ]*$/$1 $2 $3/mg;
	$file =~ s/^\n+//gs;
	$file =~ s/(?:\n )*\n+$//s;
	$file =~ s/\n\n\n+/\n\n/gs;
	$file .= "\n\n";

	print $file;
	if($file ne $oldfile) {
	  open(FILE, ">>/tmp/historyfix.p4edit");
	  print FILE " $filename";
	  close(FILE);
	  open(FILE, ">>/tmp/historyfix.patch");
		print FILE "patch -p0 << EOF\n";
    open(FROM, ">/tmp/historyfix.from"); print FROM $oldfile;
    close(FROM);
    open(TO,   ">/tmp/historyfix.to");   print TO   $file;
    close(TO);
    my $diff = `diff -Nua /tmp/historyfix.from /tmp/historyfix.to`;
    $diff =~ s!/tmp/historyfix.from!$filename.old!;
    $diff =~ s!/tmp/historyfix.to!$filename!;
    $diff =~ s/\\/\\\\/g;
    $diff =~ s/\$/\\\$/g;
    $diff =~ s/\`/\\\`/g;
    print FILE $diff;
    unlink("/tmp/historyfix.from");
    unlink("/tmp/historyfix.to");
    print FILE "EOF\n";
    close(FILE);
 }

 #if($file eq $oldfile) { exit 1 } else { exit 0 }

}

open(FILE, "</tmp/historyfix.p4edit"); $/ =
undef; $var = <FILE>; print $var . "\n";
close(FILE);
open(FILE, "</tmp/historyfix.patch" ); $/ = undef; $var = <FILE>; print $var;
close(FILE);
unlink("/tmp/historyfix.p4edit");
unlink("/tmp/historyfix.patch");

sub fixit() {
  my $argm = shift();
  #print "<argm>$1-$2-$3-$4</argm>\n";
  $argm =~ s/^(?: \n)+//sg;
  $argm =~ s/^\n+/ /s;
  $argm = "\n \n$argm";
  $argm =~ s/^[ \t]+/ /gm;
  $argm =~ s/\n -/\n */gs;
  $argm =~ s/\n \n /\n  * /gs;
  $argm =~ s/^ (.)/       $1/gm;
  $argm =~ s/[* ] \* /* /gm;
  $argm =~ s/ $//s;
  $argm =~ s/^\n+//s;
  $argm =~ s/\n+$//s;
  $argm =~ s/(.)\t/$1 /gm;
  $argm =~ s/    /  /gm;
  return $argm;
}

sub fixname() {
  my $argm = shift();
  $argm =~ s/[,<>]//g;
  return $argm;
}

