package Business::DE::Konto;

require 5.00503;
use strict;
use Cwd;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;

use base qw(Exporter);
@EXPORT_OK = qw(check custom_error printerror returnerror);

@EXPORT = qw( );
$VERSION = '0.01';
my $errorcode = {
			BLZ => [
					['Please supply a BLZ',1],
					['Please supply a BLZ with 8 digits',2],
					['Please supply a BLZ with only digits',3],
					['BLZ doesn\'t exist.',4],
					['Corrupted BLZ-File.',5],
					],
			KONTONR => [
					['Please supply a Kontonumber',6],
					['Please supply a Kontonumber with only digits',7],
					['Kontonumber is invalid',8],
					],
				};
my $check_code =
			{
			"00" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], "00"],
			"01" => ["NORMAL",10,[3, 7, 1, 3, 7, 1, 3, 7, 1], "01"],
			"02" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 2], "02"],
			"03" => ["NORMAL",10,[2, 1, 2, 1, 2, 1, 2, 1, 2], "01"],
			"04" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "02"],
			"05" => ["NORMAL",10,[7, 3, 1, 7, 3, 1, 7, 3, 1], "01"],
			"06" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "06"],
			"07" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],"02"],
			"08" => ["NORMAL",10,[2, 1, 2, 1, 2, 1, 2, 1, 2], "08"],
			"09" => ["NORMAL",11,[2, 1, 2, 1, 2, 1, 2, 1, 2], "09"],
			"10" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],"06"],
			"11" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 10],"11"],
			"12" => ["NORMAL",10,[1, 3, 7, 1, 3, 7, 1, 3, 7], "01"],
			"13" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 0],       "13"],
			"14" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "14"],
			"15" => ["NORMAL",11,[2, 3, 4, 5, 2, 3, 4, 5, 2], "06"],
			"16" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "16"],
			"17" => ["NORMAL",11,[1, 2, 1, 2, 1, 2, 1, 2, 1], "17"],
			"18" => ["NORMAL",10,[3, 9, 7, 1, 3, 9, 7, 1, 3], "01"],
			"19" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 1], "06"],
			"20" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9, 3], "06"],
			"21" => ["QUER",  10,[2, 1, 2, 1, 2, 1, 2, 1, 2], "21"],
			"22" => ["ONES",  10,[3, 1, 3, 1, 3, 1, 3, 1, 3], "00"],
			"23" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "16"],
			"24" => ["NORMAL",11,[1, 2, 3, 1, 2, 3, 1, 2, 3], "24"],
			"25" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8, 9],    "25"],
			"26" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 2, 3, 4], "06"],
			"27" => ["NORMAL",10,[2, 1, 2, 1, 2, 1, 2, 1, 2], "00"],
			"28" => ["NORMAL",11,[2, 3, 4, 5, 6, 7, 8],       "06"],
		};
my $methods = 
		{
			QUER => \&_quer,
			NORMAL => \&_normal,
		};

my ($KONTONR,$BLZ,$blzfile,$error,$result);
sub new {
	my $type = shift;
	my $args = {@_};
	$blzfile = "./BLZ.dat";
	$blzfile = $args->{BLZFILE} if (defined $args->{BLZFILE});
	die "Could not find BLZFILE ".cwd."/$blzfile." unless -e $blzfile;
	$KONTONR = $args->{KONTONR} if defined $args->{KONTONR};
	$BLZ = $args->{BLZ} if defined $args->{BLZ};
	my $self  = {};
	$self->{BLZ} = $BLZ if defined $BLZ;
	undef $error;
	bless($self, $type);
	return $self;
	
}
############################
# supply custom error messges
sub custom_error($) {
	my $self = shift;
	$errorcode = shift;
}
############################
sub check {
	my $self = shift;
	undef $error;
	my $args = {@_};
	$KONTONR = $args->{KONTONR} if defined $args->{KONTONR};
	$BLZ = $args->{BLZ} if defined $args->{BLZ};
	$self->{BLZ} = $BLZ if defined $BLZ;
	return 0 unless $self->_validBLZ($BLZ) && $self->_validKONTONR($KONTONR);
	# ok, input is okay, so now let's go into details
	return 0 unless $self->_readBLZFile($BLZ);
	push (@{$error->{MESSAGE}} , $errorcode->{KONTONR}[2]),return unless $self->pruefe($KONTONR, $result->{METHOD});
}
############################
sub _validBLZ ($) {
	my $self = shift;
	my $blz = shift;
	push (@{$error->{MESSAGE}} , $errorcode->{BLZ}[0]),return unless defined $blz;
	push (@{$error->{MESSAGE}} , $errorcode->{BLZ}[1]),return if length $blz != 8;
	push (@{$error->{MESSAGE}} , $errorcode->{BLZ}[2]),return if $blz =~ m/\D/;
	return 1;
}
############################
sub _validKONTONR($) {
	my $self = shift;
	my $kontonr = shift;
	push (@{$error->{MESSAGE}} , $errorcode->{KONTONR}[0]),return unless defined $kontonr;
	push (@{$error->{MESSAGE}} , $errorcode->{KONTONR}[1]),return if $kontonr =~ m/\D/;
	return 1;
}
############################
sub printerror() {
	my $self = shift;
	my $errormessage;
	warn "The following errors ocured:\n";
	for my $error (@{$error->{MESSAGE}}) {
		warn "$error->[0] (Error $error->[1])\n";
	}
}
############################
sub returnerror() {
	my $self = shift;
	my @returnerrors;
	for my $error (@{$error->{MESSAGE}}) {
		push @returnerrors, $error->[1];
	}
	return @returnerrors;
}
############################
sub _readBLZFile($) {
	my $self = shift;
	my $blz = shift;
	open BLZ, "<$blzfile" or die "Could not open BLZ-File $blzfile: $!";
	my $line;
	while (defined ($line = <BLZ>)) {
		last if $line =~ m/^$blz/;
	}
	push (@{$error->{MESSAGE}}, $errorcode->{BLZ}[3]),return unless defined $line;
	if (my ($D_BLZ, $D_BANK, $D_PLZ, $D_ORT, $D_METHOD, $REST) = 
				$line =~ m/^(\d{8})(.{58})(\d{5})(.{30})(\d\d)(\d)/ ) {
		$result->{BLZ} = $D_BLZ;
		($result->{BANK} = $D_BANK) =~ s/^\s+|\s+$//;
		$result->{PLZ} = $D_PLZ;
		($result->{ORT} = $D_ORT) =~ s/^\s+|\s+$//;
		$result->{METHOD} = $D_METHOD;
		$result->{REST} = $REST;
	}
	else {
		push @{$error->{MESSAGE}}, $errorcode->{BLZ}[4];
		return;
	}
	return 1;
}
############################
sub _quersumme {
	my $num = shift;
	return $num if length $num == 1;
	my $sum = do {
							my $x;
							foreach (split //, $num) {$x+=$_}
							$x
						};
	return $sum;
}
############################
sub pruefe {
	no strict 'refs';
	my $self = shift;
	my $k = shift;
	my $m = shift;
	my ($ziffer,$pruefziffer);
	if (exists $check_code->{$m}) {
		my ($method,$mod,$array,$m_alias) = @{$check_code->{$m}};
		my $sum = $self->_add($array, $k, {METHOD => $method});
		my $sub = "m$m_alias";
		if ($m == 13) {
			$pruefziffer = substr((sprintf "%010s",$k),7,1);
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			unless ($pruefziffer == $ziffer) {
				$pruefziffer = substr((sprintf "%010s",$k."00"),7,1);
				$sum = $self->_add($array, $k."00", {METHOD => $method});
				$ziffer = $sub->($self,$array,"${k}00",$sum,$mod);
			}
		}
		elsif ($m eq "15") {
			substr($k,0,5) = "00000";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		elsif ($m eq "14") {
			substr($k,0,3) = "000";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		elsif ($m eq "23") {
			substr($k,-3,3) = "";
			$pruefziffer = substr((sprintf "%010s",$k),7,1);
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		elsif ($m eq "26") {
			$k = substr($k,0,8)  unless $k =~ m/^00/;
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		elsif ($m eq "27" && $k > 999999999) {
			$sub = "m27";
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		elsif ($m eq "28") {
			$k = substr($k,0,8);
			$pruefziffer = substr($k,-1,1);
			$sum = $self->_add($array, $k, {METHOD => $method});
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
		}
		else {
			$ziffer = $sub->($self,$array,$k,$sum,$mod);
			$pruefziffer = substr($k,-1,1);
		}
		return 0 unless defined $ziffer;
		return ($ziffer == $pruefziffer)? 1 : 0
	}
	else {
		warn "Method $m not implemented yet\n";
		return 1;
	}
}
############################
sub _add {
	my $self = shift;
	my ($array, $k, $args) = @_;
	$array = [reverse @$array];
	$k = sprintf "%010s",$k;
	my $sum;
	for my $x (0..8) {
		my $add = $array->[$x] * substr($k,$x,1);
		$add = _quersumme($add) if $args->{METHOD} eq "QUER";
		$add = substr($add,-1,1) if $args->{METHOD} eq "ONES";
		$sum += $add;
	}
	return $sum;
}
############################
sub summe {
	my $self = shift;
	my @nums = @_;
	my $sum;
	$sum += $_ for @nums;
	return $sum;
}
############################
# Modulus 10, Gewichtung 2, 1, 2, 1, 2, 1, 2, 1, 2
# Die Stellen der Kontonummer sind von rechts nach links mit
# den Ziffern 2, 1, 2, 1, 2 usw. zu multiplizieren. Die jeweiligen
# Produkte werden addiert, nachdem jeweils aus den
# zweistelligen Produkten die Quersumme gebildet wurde
# (z. B. Produkt 16 = Quersumme 7). Nach der Addition
# bleiben außer der Einerstelle alle anderen Stellen
# unberücksichtigt. Die Einerstelle wird von dem Wert 10
# subtrahiert. Das Ergebnis ist die Prüfziffer (10. Stelle der
# Kontonummer). Ergibt sich nach der Subtraktion der
# Rest 10, ist die Prüfziffer 0.
# Testkontonummern:9290701, 539290858, 1501824, 1501832
sub m00 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ziffer = $mod - substr($sum,-1,1);
	$ziffer = 0 if $ziffer == 10;
	return $ziffer;
}
############################
sub m01 {
	my ($self,$array,$k,$sum,$mod)= @_;
	$sum = substr($sum,-1,1);
	my $ziffer = $mod - $sum;
	return ($ziffer == 10)? 0 : $ziffer;
}
############################
sub m02 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	return if ($rest == 1);
	return $mod - $rest;
}
############################
sub m06 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = 0}
	elsif ($rest == 0) {$ziffer = 0}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;
}
############################
sub m08 {
	my ($self,$array,$k,$sum,$mod)= @_;
	return unless $k > 60000;
	$self->m00->($array,$k,$sum,$mod);
}
############################
sub m09 {
	my ($self,$array,$k,$sum,$mod)= @_;
	return substr($k,-1,1);
}
############################
sub m11 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = 9}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;

}
############################
sub m13 {
	my ($self,$array,$k,$sum,$mod)= @_;
	substr($k,0,1)=0;
	$sum = substr($sum,-1,1);
	my $ziffer = $mod - $sum;
	$ziffer = 0 if $ziffer == 10;
	return $ziffer;

}
############################
sub m14 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	return if ($rest == 1);
	return $mod - $rest;
}
############################
sub m16 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my $ziffer;
	if ($rest == 1) {$ziffer = substr($k,-2,1);}
	elsif ($rest == 0) {$ziffer = 0}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;
}
############################
sub m17 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my @k = (split //, (sprintf "%010s",$k))[1..7];
	my $pruef = pop @k;
	$sum = $k[0] + _quersumme($k[1]*2) +
						$k[2] + _quersumme($k[3]*2) +
						$k[4] + _quersumme($k[5]*2);
	$sum--;
	my $ziffer = $sum % $mod;
	if ($ziffer == 0) {
		$ziffer = 0;
	}
	else {
		$ziffer = 10 - $ziffer;
	}
	return substr($k,-1,1) if $ziffer == $pruef;
}
############################
sub m21 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ziffer = _quersumme $sum;
	while ($ziffer > 9) {
		$ziffer = _quersumme $ziffer;
	}
	$ziffer = $mod - $ziffer;
	return $ziffer;

}
############################
sub m24 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $blz = $self->{BLZ};
	$k = sprintf "%010s", $k;
	if ($k =~ m/^[3456]/) {
		substr($k,0,1) = 0;
	}
	if (substr($k,0,1) == 9) {
		substr($k,0,3) = "000";
	}
	$k = $k + 0;
	my @k = split //,$k;
	my $pruef = pop @k;
	$sum = 0;
	my ($i);
	for (@k) {
		$sum += (($k[$i] * $array->[$i]) + $array->[$i]) % $mod;
		$i++;
	}
	my $ziffer = substr($sum,-1,1);
	return $ziffer;
}
############################
sub m25 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $rest = $sum % $mod;
	my ($ziffer);
	if ($rest == 0) {
		$ziffer = 0;
	}
	elsif ($rest == 1) {
		$ziffer = 0;
		return undef unless (substr($k,1,1) =~ m/^[89]$/);
	}
	else {
		$ziffer = $mod - $rest;
	}
	return $ziffer;
}
############################
sub m26 {
	my ($self,$array,$k,$sum,$mod)= @_;

}
############################
sub m27 {
	my ($self,$array,$k,$sum,$mod)= @_;
	my $ergebnis;
	my @trans = qw(1 4 3 2 1 4 3 2 1);
	my @zeilen = ([qw(0 1 5 9 3 7 4 8 2 6)],
								[qw(0 1 7 6 9 8 3 2 5 4)],
								[qw(0 1 8 4 6 2 9 5 7 3)],
								[qw(0 1 2 3 4 5 6 7 8 9)],
							);
	my @k = split //, $k;
	my $pruef = pop @k;
	for my $z (0..@k-1) {
		my $trans = $trans[$z] - 1;
		$ergebnis += $zeilen[$trans][$k[$z]];
	}
	$ergebnis = substr($ergebnis,-1,1);
	my $ziffer = $mod - $ergebnis;
	return $ziffer;

}
############################
sub m28 {
	my ($self,$array,$k,$sum,$mod)= @_;

}
############################
1;
__END__

=head1 NAME

Business::DE::Konto - Validating Bank-Account Numbers for Germany

=head1 SYNOPSIS

  use Business::DE::Konto;
  my $konto = Business::DE::Konto->new(%hash);


=head1 DESCRIPTION

  use Business::DE::Konto;
  my $konto = Business::DE::Konto->new(%hash);

  where %hash can have zero, one or more of the following entries:
  BLZFILE => '/path/to/BLZ.dat'
  BLZ     => 12345678
  KONTO   => 1234567890

  e.g.:

  my $konto = Business::DE::Konto->new(BLZFILE => '/path/to/BLZ.dat');

  check():
  $konto->check(%hash);
  where %hash can have zero, one or more of the following entries:
  BLZ     => 12345678
  KONTO   => 1234567890

  e.g.:
  $konto->check(BLZ => 12345678, KONTO => 1234567890);
  $konto->check(BLZ => 22233333, KONTO => 2222222222);

	or
  use Business::DE::Konto;
  my $konto = Business::DE::Konto->new(BLZ => 12345678, KONTO => 1234567890));
  $konto->check();

=head2 EXPORT

None by default. All methods are accessed over the object.

=head1 AUTHOR

Tina Mueller, tinita@cpan.org

=head1 SEE ALSO

perl(1).

=cut
