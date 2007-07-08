package Wx::Data::Plugin::Authentication::WSSE;

use strict;
use warnings;
use Digest::MD5 qw( md5_hex md5_base64 );

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(
   qw/namespace/
);

sub prepare {
   my ($class, $request, $parameters) = @_;
      
   if (ref $request eq 'Wx::Data::Engine::HTTP::Request'
       && ref $request->http_request eq 'HTTP::Request') {
      
      my $password = '{MD5}'.md5_base64($parameters->{password}).'==';

      my $nonce = _make_nonce();
      my $timestamp = _now_w3cdtf();

      my $wsse_value = md5_hex( md5_base64( $nonce . $timestamp . $password ) );
      
      $request->http_request->header( 'X-WSSE'           => $wsse_value );
      $request->http_request->header( 'X-WSSE-NONCE'     => $nonce );
      $request->http_request->header( 'X-WSSE-TIMESTAMP' => $timestamp );

      $class->NEXT::prepare($request, $parameters);
   }
   else {
      $class->NEXT::prepare($request, $parameters);
   }
}

sub validate {
   my $class = shift;
   my $password  = shift;
   my $digest    = shift;
   my $nonce     = shift;
   my $timestamp = shift;
   my $generated = md5_hex( md5_base64( $nonce . $timestamp . $password ) );
   return ( $digest eq $generated ? 1 : 0 );
}

sub _make_nonce {
   return md5_hex(md5_base64(time() . {} . rand() . $$));
}

sub _now_w3cdtf {
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime();
    $mon++; $year += 1900;

    return sprintf(
        "%04s-%02s-%02sT%02s:%02s:%02sZ",
        $year, $mon, $mday, $hour, $min, $sec,
    );
}
1;

__END__

=head1 AUTHORS

Ed Heil <ed@donorware.com>
Mike Schroeder <mike@donorware.com>
Eriam Schaffter <eriam@cpan.org>

=head1 ACKNOWLEDGEMENTS

Autrujis Tang's LWP::Authen::WSSE was a great example for this.

=cut

# HISTORY:
#
#  $Log: WSSE.pm,v $
#  Revision 1.3  2007/06/02 15:22:38  eriam
#  VICCI Tkt#:0
#  This plugin is now working.
#
#  Revision 1.2  2007/05/22 20:10:29  eriam
#  VICCI Tkt#:0
#  + move to NEXT->
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
