package Wx::Data::Engine::HTTP::Response;

use strict;
use warnings;
no strict 'refs';

use HTTP::Response;
use Data::Dumper;

use base qw/Wx::Data::Response HTTP::Response/;

__PACKAGE__->mk_accessors(
   qw/alias/
);

sub new {      
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   return $self;
}



1;


__END__

=head1 AUTHORS

Mike Schroeder <mike@donorware.com>

=head1 SEE ALSO

POE, LWP

=cut

# HISTORY:
#
#  $Log: Response.pm,v $
#  Revision 1.2  2007/06/01 18:07:05  eriam
#  VICCI Tkt#:0
#  The http engine now uses the engine's request and response.
#  The engine also creates the request in the first place.
#
