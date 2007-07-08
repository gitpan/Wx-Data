package Wx::Data::Response;

use strict;
use warnings;
no strict 'refs';

use Data::Dumper;

use base qw/Class::Accessor::Fast/;

sub debug {0}

__PACKAGE__->mk_accessors(
   qw/id content/
);

sub new {      
   my $class = shift;
   my $self = $class->SUPER::new(@_);

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
#  $Log: Response.pm,v $
#  Revision 1.2  2007/06/01 18:19:33  eriam
#  VICCI Tkt#:0
#  Cleanup.
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
