package Wx::Data::Control;

use strict;
use warnings;
no strict 'refs';

use base qw/Class::Accessor::Fast/;

sub debug {0}

__PACKAGE__->mk_accessors(
   qw/data_manager response_id/
);

sub refresh_data {
   my $self = shift;
   my ($request, $parameters)  = @_;

   $parameters->{'control'} = scalar($self);
   
   unless (defined $self->data_manager) {
      $self->data_manager($parameters->{'data_manager'})
   }
   
   # NEEDS FIX !! use DeleteItems instead
   # eventually it's not the appropriate place to
   # empty the control ...
   #if (my $code = $self->can('ClearAll') ) {
   #   $code->($self);
   #}

   POE::Kernel->post($self->data_manager, 'request', $request, $parameters);
}


sub receive_data {
   my $self = shift;
   my ($response) = @_;

   $self->response_id($response->id);

   if (my $code = $self->can('Populate') ) {
      $code->( $self, @_);
   }
}


1;

__END__

=head1 NAME

Wx::Data::Control - Retrieving data asynchrounously for Wx control

=head1 DESCRIPTION

In your controls classes you can simply add Wx::Data::Control to the base classes,
this will give your the opportunity, provided that you have already spawned the
Wx::Data::Manager, to refresh_data from a data source.

The response will be sent to the Populate method of the control that you'll
have to implement according to the response sent, which essentially depends
on the engine that you selected (so no surprise, using the HTTP engine
will provide you a Wx::Data::Engine::HTTP::Response object).

See the Wx::Data::Manager for detailled explanation on how to connect to a
data source and what engines are supported yet.

=head1 SYNOPSYS

So in your controls you can do like this

   package Control;
   
   use base qw/Wx::Frame Wx::Data::Control/;
   
   sub Populate {
      my $self = shift;
      my ($response) = @_;
      
      # hmm .. now would be the good time
      # to implement this since data should
      # be there anytime soon
   }

And later in your code

   # that's very wxPerl'ish
   my $control = Control->new(undef, -1, 'test', [0,0], [10,10]);

   # will request the data source and send the result back to
   # our control instance by calling the Populate method.
   
   $control->refresh_data({
      my  => 'parameters'
   });


=head1 AUTHORS

Ed Heil <ed@donorware.com>, Mike Schroeder <mike@donorware.com>, Eriam Schaffter <eriam@cpan.org>

=head1 SEE ALSO

L<Wx::Data::Manager>, Wx::Data::Engine::*

=cut

# HISTORY:
#
#  $Log: Control.pm,v $
#  Revision 1.4  2007/06/02 15:30:16  eriam
#  VICCI Tkt#:0
#  Seems it's more appropriate to clean the controls
#  before a refresh on the client code side
#
#  Revision 1.3  2007/06/01 18:20:34  eriam
#  VICCI Tkt#:0
#  Added POD.
#
#  Revision 1.2  2007/05/21 17:55:15  eriam
#  VICCI Tkt#:0
#  +plugins
#  +flow completed
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
#  Revision 1.2  2007/02/03 18:19:06  eriam
#  VICCI Tkt#:0
#
#  cleanup and is working with FindChild
#
#  Revision 1.1  2007/01/19 14:56:50  eriam
#  VICCI Tkt#:0
#
#  initial commit
#
