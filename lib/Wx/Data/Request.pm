package Wx::Data::Request;

use strict;
use warnings;
no strict 'refs';

use Data::Dumper;

use base qw/Class::Accessor::Fast/;

sub debug {0}

__PACKAGE__->mk_accessors(
   qw/id content parameters priority delay type is_valid control/
);

sub new {
   my $class = shift;
   my $self = $class->NEXT::new(@_);

   $self->priority('post') unless defined $self->priority;
   $self->delay(0)         unless defined $self->delay;  
   $self->type('request')  unless defined $self->type;   
   $self->is_valid(1)      unless defined $self->is_valid;  

   return $self;
}


sub prepare {
   my $request = @_;
   
   return $request;
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
#  Revision 1.2  2007/06/01 18:18:27  eriam
#  VICCI Tkt#:0
#  Added a is_valid accessor so the request can be discarded by plugins.
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
