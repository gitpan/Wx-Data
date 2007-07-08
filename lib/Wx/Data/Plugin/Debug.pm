package Wx::Data::Plugin::Debug;

use strict;
use warnings;
no strict 'refs';

use Wx::Perl::Carp;
sub debug { 0 };


sub spawn {
   Wx::LogMessage("Wx::Data spawning debugger");
}


sub prepare {
   my ($class, $request) = @_;
   
   Wx::LogMessage("Wx::Data requesting ".$request->id);
   
   $class->NEXT::prepare($request);
}

sub receive {
   my ($class, $response) = @_;
   
   Wx::LogMessage("Wx::Data receiving ".$response->id);
   
   $class->NEXT::receive($response);
}


1;

__END__

=head1 AUTHORS

Mike Schroeder <mike@donorware.com>, Eriam Schaffter <eriam@cpan.org>

=head1 SEE ALSO

Wx::Data

=cut

# HISTORY:
#
#  $Log: Debug.pm,v $
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
#  Revision 1.12  2007/03/16 11:16:36  eriam
#  VICCI Tkt#:0
#  - eval: for streaming we don't fail when we can't deserialize
#
#  Revision 1.11  2007/03/08 21:56:52  eriam
#  VICCI Tkt#:0
#  ! returns an undef
#
#  Revision 1.10  2006/09/24 10:29:22  eriam
#  VICCI Tkt#:0
#  - dump and debug info
#
#  Revision 1.9  2006/09/20 18:53:32  eriam
#  VICCI Tkt#:0
#  - auth_token
#  cleanup
#
#  Revision 1.8  2006/09/09 15:49:04  eriam
#  VICCI Tkt#:0
#  + auth_token
#
#  Revision 1.7  2006/07/22 15:05:20  eriam
#  VICCI Tkt#: 0
#  ! version
#
#  Revision 1.6  2006/07/22 09:37:58  eriam
#  VICCI Tkt#:0
#  ! logging via PoCo::Logger
#
#  Revision 1.5  2006/07/07 14:20:49  eriam
#  VICCI Tkt#:0
#  pre phase 2
#
#  Revision 1.4  2006/06/19 19:10:21  eriam
#  VICCI Tkt#: 0
#  pod
#
#  Revision 1.3  2006/06/12 17:29:11  eriam
#  VICCI Tkt#:0
#  cleanup
#
#  Revision 1.2  2006/05/22 13:00:37  eriam
#  VICCI Tkt#: 0
#  + comments
#
#  Revision 1.1  2006/05/12 22:34:02  eriam
#  VICCI Tkt#: 0
#  + Wx::Data::Serializer will allow to serialize or not requests to be passed to Wx::Data::Client::*
#
#