package Checkid;

use 5.006001;
# use strict;
# use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Checkid ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(checkid
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(checkid
	
);

our $VERSION = '0.9';

sub checkid {

	my $ACCESS_LEVEL = $_[1];

	$ENV{HTTP_COOKIE} = $ENV{HTTP_COOKIE} || "";

	@Cookie = split(/\;/,$ENV{HTTP_COOKIE});
	foreach (@Cookie) {
        	($Name,$Value) = split(/\=/,$_);
	        $Name =~ s/^ //g;
        	$Value =~ tr/\"//d;
	        $Cookie{$Name} = $Value;
	}

	$Cookie = $Cookie{'fpa-cookie'} || "*xx*";

	open(COOKIE,"/projects/tmp/$Cookie");
	while (<COOKIE>) {
        	chomp($_);
	        ($Name,$Value) = split(/\t/,$_);
        	$COOKIE->{$Name} = $Value;
	}

	close(COOKIE);
	$COOKIE->{NEXT_AD} = $Cookie{'fpa-next_advert'};

#  Check that the cookie email = COOKIE email

	unless ($Cookie{'fpa-uid'} && $Cookie{'fpa-uid'} eq $COOKIE->{ID}) {
        	print<<EOD;
Content-Type: text/html
Status: 301
Location: /error.html

EOD
	        exit;
	}

#  Now check the access level

#	unless ($COOKIE->{ACCESS} || $ACCESS_LEVEL == 0) {
	unless ($COOKIE->{ACCESS} >= $ACCESS_LEVEL) {

        	print<<EOD;
Content-Type: text/html
Status: 301
Location: /cgi-bin/fpa/upgrade.pl

EOD
	        exit;
	}
	return $COOKIE;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Checkid - Perl extension to check the user's id and access rights based on the uid cookie passed in HTML headers.

=head1 SYNOPSIS

  use Checkid(Access Level);

=head1 DESCRIPTION

This module gets the user's core details from a cookie file created at the time of login (returned as a hashref) using a cookie embedded in the HTML headers as the key to read a file.

As well as some basic information as to the type of account (eg whether it is VAT registered, the year end date etc) this file contains a set of flags for each chargable function.  A 'valid until' date is stored in the company record for each chargable item and, at the time of login, these dates are compared to the current date to see whether or not that item is active.  Each of these flags is then stored (as true '1' or false '') as part of the cookie hashref and can then be checked as appropriate.

Currently chargable modules are as follows:-

  +-----------------------------------------------------+-----------------+--------------------+
  |  Description                                        |  record field   |  hashref           |
  +-----------------------------------------------------+-----------------+--------------------+
  | Whether the user is a user of the 'free' system     |  comfree        |  ACCESS            |
  | Whether adverts should be suppressed                |  comno_ads      |  NO_ADS            |
  | Whether Repeat Invoices are allowed                 |  comrep_invs    |  REP_INVS          |
  | Whether automatic statements can be produced        |  comstmts       |  STMTS             |
  | Whether uploads are allowed                         |  comuplds       |  UPLDS             |
  | Whether user's logo should be printed               |  compt_logo     |  PT_LOGO           |
  | Whether to automatically update VAT details to HMRC |  comhmrc        |  HMRC              |
  | Whether support has been purchased                  |  comsuppt       |  SUPPT             |
  +-----------------------------------------------------+-----------------+--------------------+

To enable any of these features just update the relevant date to some time in the future.

NOTE
1  -  It is likely that both UPLDS and SUPPT will each have an additional field to keep a running total of how much bandwidth/credit is still available.
2  -  Currently ACCESS is the result of 'or'ing together regmembership and comno_ads so that the user only has access to the main system if s/he has either opted in to ads and email or has paid for no adverts.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Doug Conran, E<lt>dconran@corunna.comtE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Doug Conran

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
