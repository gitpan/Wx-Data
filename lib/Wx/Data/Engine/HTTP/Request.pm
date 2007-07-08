package Wx::Data::Engine::HTTP::Request;

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Request;

use base qw/Wx::Data::Request/;

__PACKAGE__->mk_accessors(
   qw/uri method http_request/
);

sub new {      
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->uri('/') unless defined $self->uri; 
   $self->method('GET') unless defined $self->method; 

   $self->http_request(HTTP::Request->new);

   return $self;
}


1;


__END__

=head1 AUTHORS

Ed Heil <ed@donorware.com>
Mike Schroeder <mike@donorware.com>
Eriam Schaffter <eriam@cpan.org>

=head1 SEE ALSO

POE, LWP

=cut

# HISTORY:
#
#  $Log: Request.pm,v $
#  Revision 1.3  2007/06/02 15:27:45  eriam
#  VICCI Tkt#:0
#  The HTTP::Request is encapsulated to make plugins able to modify it directly.
#
#  Revision 1.2  2007/06/01 18:07:05  eriam
#  VICCI Tkt#:0
#  The http engine now uses the engine's request and response.
#  The engine also creates the request in the first place.
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
