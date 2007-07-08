#!/usr/bin/perl -w

use strict;

use POE qw( Loop::Wx );
use POE::Session;

my $PORT = 2080;
my $IP = "localhost";

# This is our data manager
package Manager;

require Wx::Data::Manager;
import Wx::Data::Manager;

Wx::Data::Manager->spawn({
   alias    => 'test_data_manager',
   engine   => {
      name     => 'Wx::Data::Engine::HTTP',
      server   => "http://www.eriamschaffter.info",
      alias    => 'http_engine'
   },
});

# This is our control
package Control;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE);
use base qw/Wx::Frame Wx::Data::Control/;
use POE::Kernel;

sub new {
   my $class = shift;
   my $self = $class->SUPER::new( undef, -1, 'Test', [0, 0], [0,0] );
   
   $self->refresh_data(undef, {
      uri            => "/catalyst/quote",
      data_manager   => 'test_data_manager',
   });

}

sub Populate {
   my $self = shift;
   my ($response) = @_;
   
   my ($quote, $author) = split (/~/, $response->content);
   
   Wx::MessageBox($quote, $author);
   
   exit;
}

# This is our control
package main;
use POE::Session;

POE::Session->create(
   inline_states => {
      _start   => \&_start,
      quit   => \&quit,
      _KEEPALIVE  => sub {
            $_[KERNEL]->delay('_KEEPALIVE', 20);
         },
   }
);

sub _start {
   
   no strict 'subs';
   
   my $control = Control->new();
   
   $_[KERNEL]->alias_set('test');
   $_[KERNEL]->yield('_KEEPALIVE');

}

sub quit {
   $_[KERNEL]->delay('_KEEPALIVE');
   exit;
}


my $app = Wx::SimpleApp->new;

#POE::Kernel->loop_run();
POE::Kernel->run();

