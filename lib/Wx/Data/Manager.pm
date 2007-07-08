package Wx::Data::Manager;

use strict;
use warnings;
no strict 'refs';

use POE::Session;
use Class::Inspector;
use NEXT;

use Data::Dumper;

use base qw/Class::Accessor::Fast/;
our @ISA;
our $VERSION = "0.01_01";

__PACKAGE__->mk_accessors(
   qw/alias engine prepare_plugins receive_plugins/
);

my $controls;

sub debug { 0 }

sub import {
    my ( $class, @arguments ) = @_;
   
   foreach (@arguments) {
      my $module = $_;
      
      if ($module !~ /^\+/) {
         $module = "Wx::Data::Plugin::".$module;
      }
      
      unless (Class::Inspector->loaded($module)) {
         require Class::Inspector->filename($module);
      }
      
      # hmm is this really bad ?
      push @ISA, $module;
   }
}

sub spawn {      
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   POE::Session->create(
      object_states => [
         $self => [
            '_start',
            '_stop',
            '_handle_call',
            'prepare',
            'request',
            'receive',
            'distribute_data',
            'keepalive',
         ]
      ]
   );
   
   # the plugins are imported as inherited classes at runtime
   # these are now given the opportunity to spawn
   $class->NEXT::spawn(@_);

   return $self;
}

sub _start {
   my ( $self, $kernel, $heap, $session, $sender ) = @_[OBJECT, KERNEL, HEAP, SESSION, SENDER];
   
   $kernel->alias_set($self->alias);
   
   unless (Class::Inspector->loaded($self->engine->{name})) {
      require Class::Inspector->filename($self->engine->{name});
   }

   # the engine is now given a chance to spawn
   if (my $code = $self->engine->{name}->can('spawn') ) {
      $self->engine->{'manager'} = $self->alias;
      $self->engine($code->($self->engine->{name}, $self->engine));
   }

   $kernel->delay_set('keepalive', 60);
}
                                                                                
sub keepalive { 
   $_[KERNEL]->delay_set('keepalive', 30); 
}

sub _stop {
   my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION];
   Wx::LogVerbose("Stopping Data Manager Service");
}

sub request {
   my ( $self, $heap, $session, $sender ) = @_[OBJECT, HEAP, SESSION, SENDER];

   # the engine builds the request in the first place
   # and the resquest is inherited from Wx::Data::Request
   my $request = POE::Kernel->call($self->engine->alias, 'prepare', {
      content  => $_[ARG0],
      %{$_[ARG1]},
   });
   
   # the plugins can now prepare the request
   $request = POE::Kernel->call($self->alias, 'prepare', $request, $_[ARG1] );

   # the plugin can eventually discard the request for any
   # reason, actually the cache plugin does if it found
   # a cached response that matches the request
   if ( $request->is_valid ) {
      POE::Kernel->call($self->alias, '_handle_call', $request, $_[ARG1] );
   }
}

sub prepare {
   my ( $self, $heap, $session, $sender ) = @_[OBJECT, HEAP, SESSION, SENDER];
   my $request    = $_[ARG0];
   my $parameters = $_[ARG1];
   
   # the controls hash keeps track of the controls
   # making the request
   $controls->{$request->id} = $request->control;
   
   # NEXT is a great tool
   $self->NEXT::prepare($request, $parameters);

   return $request;
}

sub _handle_call {
   my ( $self, $kernel, $heap, $session, $sender ) = @_[OBJECT, KERNEL, HEAP, SESSION, SENDER];
   my $request = $_[ARG0];

   # until now we've been using kernel calls because here we may
   # need to make a blocking call, default is post of course
   my $call_post = $request->priority;
   
   POE::Kernel->$call_post($self->engine->alias, $request->type, $request); 

   return;
}

# actually this is not a POE event because
# the cache plugin and eventually other
# plugins may just call this directly
sub distribute_data {
   my ( $self, $response ) = @_;
      
   $controls->{$response->id}->receive_data($response);
}

sub receive {
   my ( $self, $kernel, $heap, $session ) = @_[OBJECT, KERNEL, HEAP, SESSION];
   my $response = $_[ARG0];

   # plugins are given a chance to receive and deal with the
   # response
   $self->NEXT::receive($response);
   
   if ( defined $response->content ) {
      $self->distribute_data($response);
   }
}

1;
__END__

=head1 NAME

Wx::Data::Manager - Managing asynchrounous Wx controls data requests (with POE!)

=head1 DESCRIPTION

Wx::Data::Manager gives the capabilities to fetch data directly from your Wx
controls, asychronously !

Since it uses POE, you should know that it can be used in your programs if you
already have a POE loop running. But since you use wxPerl we believe the POE
event loop is very appropriate for wxPerl and we encourage you to take a look
at this.

Wx::Data::Manager is very modular and you can add functionnalities as plugins
very simply, you can add your own plugins too !

You can use different engines to access data sources through various protocols.

The first release comes with a single engine, which is HTTP.

=head1 SYNOPSYS

   use Wx::Data::Manager;
   
   # let's fetch something from yahoo, it's possible to spawn several
   # data managers that would reply on differents POE aliases with
   # various engines
   # each data manager creates its own session and other session as
   # needed by engines or plugins
   
   Wx::Data::Manager->spawn({
      alias    => 'test_data_manager',
      engine   => {
         name     => 'Wx::Data::Engine::HTTP',
         server   => "http://www.yahoo.com",
         alias    => 'http_engine'
      },
   });

   # the POE loop ! .. here comes the voodoo 
   
   POE::Kernel->run;

   # you can create controls and make them inherit from Wx::Data::Controls
   # that will allow you do data calls very easily from your controls like this
   
   my $control = Control->new(undef, -1, 'test', [0,0], [10,10]);

   $control->refresh_data( undef, {
      uri            => "/",
      data_manager   => 'test_data_manager',
   });

=head1 AUTHORS

Ed Heil <ed@donorware.com>, Mike Schroeder <mike@donorware.com>, Eriam Schaffter <eriam@cpan.org>

=head1 SEE ALSO

L<Wx>, L<POE>, Wx::Data::Engine::*

=cut

# HISTORY:
#
#  $Log: Manager.pm,v $
#  Revision 1.5  2007/06/02 15:31:41  eriam
#  VICCI Tkt#:0
#  The plugins deserve also the right to see what are the request's
#  parameters. So here it is.
#
#  Revision 1.4  2007/06/01 18:14:12  eriam
#  VICCI Tkt#:0
#  Delegated the requests creation to the engine.
#  Added some POD.
#
#  Revision 1.3  2007/05/22 20:02:47  eriam
#  VICCI Tkt#:0
#  + move to NEXT->
#  + plugins now are added within the use Wx::Data::Manager
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
