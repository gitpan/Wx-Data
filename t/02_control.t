#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

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
   
   require Wx::Data::Manager;
   import Wx::Data::Manager;
   
   Wx::Data::Manager->spawn({
      alias    => 'test_data_manager',
      engine   => {
         name     => 'Wx::Data::Engine::HTTP',
         server   => "http://$IP:$PORT",
         alias    => 'http_engine'
      },
   });
   
   # This is our control
   package Control;
   use Wx qw(:everything);
   use base qw/Wx::Frame Wx::Data::Control/;
   use Test::More;
   
   sub Populate {
      my $self = shift;
      my ($response) = @_;
      ok ($response->content eq "this is top", 'populate control');
      exit;
   }

   # This is our control
   package main;
   use POE::Session;
   
   POE::Session->create(
      inline_states => {
         _start   => \&_start
      }
   );
   
   sub _start {
      
      no strict 'subs';
      my $control = Control->new(undef, -1, 'test', [0,0], [10,10]);
      
      $control->refresh_data({
         test  => 1
      }, {
         uri            => "/",
         data_manager   => 'test_data_manager',
      });
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
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '^/$',
                                'SESSION'       =>      'HTTP_GET',
                                'EVENT'         =>      'TOP',
                        },
                ],
    );
    # Create our own session to receive events from SimpleHTTP
    POE::Session->create(
      inline_states => {
              '_start'        => sub {   $_[KERNEL]->alias_set( 'HTTP_GET' ) },
              'TOP'           => \&top,
      },
    );
    $poe_kernel->run;    
}

sub top
{
    my ($request, $response) = @_[ARG0, ARG1];
    $response->code(200);
    $response->content_type('text/plain');
    $response->content("this is top");
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
