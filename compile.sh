#! /bin/sh --
# by pts@fazekas.hu at Sun Mar 31 03:44:31 CEST 2024

export ELFOSFIX_PL='
BEGIN { $^W = 1 }
use integer;
use strict;
my $from_oscode=0; # $ELF_os_codes{"SYSV"};
my $to_oscode=3;   # $ELF_os_codes{"GNU/Linux"};

for my $fn (@ARGV) {
  my $f;
  if (!open $f, "+<", $fn) {
    print STDERR "$0: $fn: $!\n";
    next
  }
  my $head;
  # vvv Imp: continue on next file instead of die()ing
  die if 8!=sysread($f,$head,8);
  if (substr($head,0,4)ne"\177ELF") {
    print STDERR "$0: $fn: not an ELF file\n";
    close($f); next;
  }
  if (vec($head,7,8)==$to_oscode) {
    print STDERR "$0: info: $fn: already fixed\n";
  }
  if ($from_oscode!=$to_oscode && vec($head,7,8)==$from_oscode) {
    vec($head,7,8)=$to_oscode;
    die if 0!=sysseek($f,0,0);
    die if length($head)!=syswrite($f,$head);
  }
  close($f);
}'

set -ex

test "${0%/*}" = "$0" || cd "${0%/*}"

type xstatic
type sstrip
type perl
type gcc  # Tested with GCC 4.8.4.
type tar
type patch
type gzip
type touch
type make
test -f binutils-2.7.tar.gz
test -f pts-binutils-2.7.patch

if true; then
  rm -rf binutils-2.7
  tar xzvf binutils-2.7.tar.gz  # Creates binutils-2.7/
  (cd binutils-2.7 && patch -p1 <../pts-binutils-2.7.patch) || exit "$?"
  (cd binutils-2.7 && CC="xstatic gcc" ./configure) || exit "$?"
  (cd binutils-2.7 && make) || exit "$?"
fi
sstrip binutils-2.7/gas/as.new binutils-2.7/ld/ld.new
perl -e 'eval($ENV{ELFOSFIX_PL});die$@if$@' binutils-2.7/gas/as.new binutils-2.7/ld/ld.new
touch -d '1996-07-15' binutils-2.7/gas/as.new binutils-2.7/ld/ld.new
mv binutils-2.7/gas/as.new as
mv binutils-2.7/ld/ld.new ld
rm -rf binutils-2.7
ls -l as ld

: "$0" OK.

