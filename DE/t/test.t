use lib "../..";
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::DE::Konto;
my $konto = Business::DE::Konto->new(BLZFILE => "./BLZ.dat");
exit unless defined $konto;
print "ok 1\n";
my $blz = 10090000;
my $kontonr = 94012341;
if ($konto->check(BLZ=>$blz, KONTONR=>$kontonr)) {
	print "ok 2\n";
}
else {
	$konto->printerror();
	my @error = $konto->returnerror();
	print join "\n", @error;
}
$kontonr = 5073321010;
if ($konto->check(BLZ=>$blz, KONTONR=>$kontonr)) {
	print "ok 3\n";
}
else {
	$konto->printerror();
	my @error = $konto->returnerror();
	print join "\n", @error;
}

$loaded = 1;
exit;
