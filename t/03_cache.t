#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use POE::Kernel;
use POE::Component::Server::SimpleHTTP;

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
      Cache
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
      $self->{compte}++;
      
      #print $response->content."\n";

      ok ($response->content eq "this is top 1", 'populate control '.$self->{compte});
      exit if $self->{compte} == 2;
   }
   
   # This is our control
   package main;
   use POE::Session;
   
   POE::Session->create(
      inline_states => {
         _start     => \&_start,
         first_get  => \&first_get,
         second_get => \&second_get,
      }
   );

   sub first_get {
      $_[HEAP]->{control}->refresh_data({
         test  => 1
      });
      $_[KERNEL]->delay('second_get', 2);
   }

   sub second_get {
      $_[HEAP]->{control}->refresh_data({
         test  => 1
      });
   }

   sub _start {
    
      $_[HEAP]->{control} = Control->new();
      
      $_[HEAP]->{control}->data_manager('test_data_manager');
      
      $_[KERNEL]->yield('first_get');
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
                $_[HEAP]->{i} = 0;
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
    $response->content("this is top ".++$_[HEAP]->{i});
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
