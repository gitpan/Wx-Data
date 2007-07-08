#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use POE::Kernel;
use POE::Component::Server::SimpleHTTP;
use Data::Serializer;

my $PORT = 2080;
my $IP = "localhost";

# test succeeds if we use 63 characters
#my $test_data = "X"x63;
# test fails if we use 64 characters
my $test_data = "X"x64;

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
      ok ($response->content eq $test_data, 'populate control');
      exit if $response->content eq $test_data;
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
    # we are the child
    POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [ {
                     'DIR'           =>      '^/$',
                     'SESSION'       =>      'HTTP_GET',
                     'EVENT'         =>      'TOP',
                },
                ],
    );
    # Create our own session to receive events from SimpleHTTP
    POE::Session->create(
      inline_states => {
              '_start'        => sub {
                $_[KERNEL]->alias_set( 'HTTP_GET' )
              },
              'TOP'           => \&top,
      },
    );
    $poe_kernel->run;    
}

sub top {
    my ($request, $response) = @_[ARG0, ARG1];
    $response->code(200);
    $response->content_type('text/plain');
    my $serializer = Data::Serializer->new;
    my $data = $serializer->serialize($test_data);
    $response->content($data);
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
