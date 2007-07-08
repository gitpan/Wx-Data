#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use POE::Kernel;
use POE::Component::Server::SimpleHTTP;
use Data::Serializer;

my $PORT = 2080;
my $IP = "localhost";

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
    }
}


if ($pid) {
   # This is our data manager
   package Manager;
   
   use Wx::Data::Manager qw/
    Serializer
   /;
   
   Wx::Data::Manager->spawn({
        alias    => 'test_data_manager',
        engine   => {
            name     => 'Wx::Data::Engine::HTTP',
            server   => "http://$IP:$PORT",
            alias    => 'http_engine'
        }
   });
   
   # This is our control
   package Control;
   use base 'Wx::Data::Control';
   use Test::More;
   
   sub Populate {
      my $self = shift;
      my ($response) = @_;
      ok ($response->content eq ("this is top " x 50), 'populate control');
      exit if $response->content eq ("this is top " x 50);
   }
   
   # This is our control
   package main;
   use POE::Session;
   
   POE::Session->create(
      inline_states => {
         _start => \&_start,
         get    => \&get,
      }
   );

   sub get {
      $_[HEAP]->{control}->refresh_data({
         test  => 1
      }, {
         uri   => "/"
      });
   }

   sub _start {
      $_[HEAP]->{control} = Control->new({
         data_manager   => 'test_data_manager',
         data_engine    => 'Wx::Data::Engine::HTTP',
      });
      
      $_[KERNEL]->yield('get');
   }
   
   POE::Kernel->run;
}
else {                          
    POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
               		{
               			'DIR'		=>	'.*',
               			'SESSION'	=>	'HTTP_GET',
               			'EVENT'		=>	'GOT_MAIN',
               		},
                ],
    );
    # Create our own session to receive events from SimpleHTTP
    POE::Session->create(
                inline_states => {
                        '_start'        => sub {   
                           $_[KERNEL]->alias_set( 'HTTP_GET' );
                           $_[KERNEL]->yield('keepalive');
                        },
                  		'GOT_MAIN'	   =>	\&GOT_MAIN,
                  		'GOT_STREAM'	=>	\&GOT_STREAM,
		                  keepalive      => \&keepalive,
                },   
    );
    
    POE::Kernel->run;
}


sub GOT_MAIN {
    my( $kernel, $heap, $request, $response, $dirmatch ) = @_[KERNEL, HEAP, ARG0 .. ARG2 ];
    
    # Do our stuff to HTTP::Response
    $response->code( 200 );
   
    $response->content_type("text/plain");
    $response->content("text/plain");
    my $serializer = Data::Serializer->new;
    $heap->{data} = $serializer->serialize("this is top " x 50);
    
    # sets the response as streamed within our session with the stream event
    $response->stream(
       session  => 'HTTP_GET',
       event    => 'GOT_STREAM'
    );   
    
    $heap->{'count'} ||= 2;
    
     # We are done!
     $kernel->yield('GOT_STREAM', $response );
}


sub GOT_STREAM {
   my ( $kernel, $heap, $response ) = @_[KERNEL, HEAP, ARG0];

    # lets go on streaming ...
    if ($heap->{'count'} > 0) {
	
        my $chunk;
        
        if ($heap->{'count'} == 2) {
            my $chunk_size = length($heap->{data}) / 2;
            $chunk = substr($heap->{data}, 0, $chunk_size);
            $heap->{data} = substr($heap->{data}, $chunk_size);
        }
        else {
            $chunk = $heap->{data};
        }
        
        $heap->{'count'}--;
        
        $response->content($chunk);
        
        POE::Kernel->post('HTTPD', 'STREAM', $response);
    }
    else {
	POE::Kernel->post('HTTPD', 'CLOSE', $response );
    }
}

sub keepalive { 
   my ( $heap ) = @_[HEAP];

   $_[KERNEL]->delay_set('keepalive', 1);
}

