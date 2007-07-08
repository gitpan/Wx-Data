#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use POE::Kernel;
use POE::Component::Server::SimpleHTTP;
use Data::Dumper;

use Wx::Data::Plugin::Authentication::WSSE;  

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
      Authentication::WSSE
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

      if ($response->content =~ /this should succeed/) {
         ok ($response->content eq "this should succeed=1", 'correct password is ok');
         exit;
      }
      elsif ($response->content =~ /this should fail/) {
         ok ($response->content eq "this should fail=0", 'wrong password is ok');
      }

      #exit;
   }
   
   # This is our control
   package main;
   use POE::Session;
   
   POE::Session->create(
      inline_states => {
         _start   => \&_start,
         success  => \&success,
         miserable_failure     => \&miserable_failure,
      }
   );

   sub success {
      $_[HEAP]->{control}->refresh_data("this should succeed", {
         password => 'testing',
         method   => 'POST'
      });
   }

   sub miserable_failure {
      $_[HEAP]->{control}->refresh_data("this should fail", {
         password => 'is_a_failure',
         method   => 'POST'
      });
      
      $_[KERNEL]->yield('success');
   }

   sub _start {
      $_[HEAP]->{control} = Control->new({
         data_manager   => 'test_data_manager',
         data_engine    => 'Wx::Data::Engine::HTTP',
      });
      
      $_[KERNEL]->yield('miserable_failure');
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

sub top {
   my ($request, $response) = @_[ARG0, ARG1];
   
   # dude ! we know the password already
   # that's cheating ..
   my $tmp_password = '{MD5}risfylFZSeXVT7IrjtlVdQ==';
   
   my $auth = Wx::Data::Plugin::Authentication::WSSE->validate(
      $tmp_password,
      $request->headers->{'x-wsse'},
      $request->headers->{'x-wsse-nonce'},
      $request->headers->{'x-wsse-timestamp'},
   );
   
   $response->code(200);
   $response->content_type('text/plain');
   $response->content($request->content."=".$auth);
   
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
