package Wx::Data::Engine::HTTP;

use strict;
use warnings;
no strict 'refs';

$| = 1;

use POE::Session;;
use URI::Escape;
use HTTP::Request;
use POE qw(Component::Client::HTTP);
use LWP::UserAgent;
use Data::Dumper;

use Wx::Data::Engine::HTTP::Request;
use Wx::Data::Engine::HTTP::Response;

use base qw/Class::Accessor::Fast/;

sub debug {0}

my $buffer;

__PACKAGE__->mk_accessors(
   qw/alias manager server/
);

sub spawn {      
   my $class = shift;
   my $self = $class->SUPER::new(@_);
   my $opt = @_;

   $self->alias(scalar($self)) unless defined $self->alias;

   POE::Session->create(
      object_states => [
         $self => [
            '_start',
            '_stop',
            'request',
            'response',
            'prepare',
            'keepalive',
         ]
      ]
   );

   return $self;
}

sub _start {
   my ($self, $kernel, $heap, $session ) = @_[OBJECT, KERNEL, HEAP, SESSION ];

   $kernel->alias_set($self->alias);

   # instantiate a user agent for blocking calls
   $heap->{blocking_ua} = LWP::UserAgent->new(
      agent => 'Wx::Data::Engine::HTTP'
   );

   # the brand new PoCo::Client::HTTP
   POE::Component::Client::HTTP->spawn(
      Agent     => 'Wx::Data::Engine::HTTP',
      Alias     => $self->alias.'ua',
      Protocol  => 'HTTP/1.1',
      From      => 'WxData',
      Streaming => 4096,
   );
                                           
   $kernel->delay_set('keepalive',60);
}

sub prepare {
   my ( $self, $kernel, $heap, $session ) = @_[OBJECT, KERNEL, HEAP, SESSION];
   my $parameters = $_[ARG0];
  
   my $request = Wx::Data::Engine::HTTP::Request->new($parameters);   
  
   $request->id($self->server.$request->uri) unless defined $request->id;
   
   return $request;
}

sub request {
   my ( $self, $kernel, $heap, $session, $sender ) = @_[OBJECT, KERNEL, HEAP, SESSION, SENDER];
   my $request = $_[ARG0];
   
   # http-yfing the request ...
   $request->http_request->method($request->method);
#   $request->http_request->method('GET');
   $request->http_request->protocol('HTTP/1.1');
   $request->http_request->uri($self->server.$request->uri);
   $request->http_request->content($request->content);
   $request->http_request->header('Wx-data-id' => $request->id);

   $kernel->post(
      $self->alias.'ua',
      'request',
      'response',
      $request->http_request,
   );
}

sub response {
   my ( $self, $kernel, $heap, $session, $request_packet, $response_packet )
      = @_[OBJECT, KERNEL, HEAP, SESSION, ARG0, ARG1];

   # HTTP::Request
   my $data;
   my $request       = $request_packet->[0];
   my $http_response = $response_packet->[0];
   my $id;

   if ($request->header('Wx-data-id')) {
      $id = $request->header('Wx-data-id');
   } else {
      $id = $http_response->base->as_string;
   }
   
   if (defined $buffer->{$id}) {
      $data = $response_packet->[1];
   }
   else {
      $data = $http_response->content.$response_packet->[1];
      $buffer->{$id} =
         $http_response->content.$response_packet->[1];
   }

   no warnings;
   #$data =~ s/\n//g;
   #$data .= "\n\n\n";
   
   if (length($data) > 0) {

      my $response = Wx::Data::Engine::HTTP::Response->new({
         content  => $data,
         id       => $id,
      });
   
      $kernel->post($self->manager, 'receive', $response );
   }
}

sub keepalive { 
   $_[KERNEL]->delay_set('keepalive',3) unless $main::quit; 
}

sub _stop {
   my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION];
   Wx::LogVerbose("Stopping HTTP Service");
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
#  $Log: HTTP.pm,v $
#  Revision 1.5  2007/06/08 20:41:32  ed
#  VICCI Tkt#:0
#
#  + assure response id is same as request id even if request id is arbitrary
#
#  Revision 1.4  2007/06/02 15:26:03  eriam
#  VICCI Tkt#:0
#  We dont need to create an HTTP::Request just before sending it to the client component since it is an almost valid HTTP::Request that arrives.
#
#  Revision 1.3  2007/06/01 18:07:05  eriam
#  VICCI Tkt#:0
#  The http engine now uses the engine's request and response.
#  The engine also creates the request in the first place.
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
