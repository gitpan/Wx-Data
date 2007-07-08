package Wx::Data::Plugin::Serializer;

use strict;
use warnings;

use Data::Serializer;
use Data::Dumper;
sub debug { 0 };

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(
   qw/serialize_engine crypto secret/
);

my $data_encryption;
my $buffer;

sub prepare {
   my ($class, $request) = @_;
   
   my $data = $data_encryption->serialize_engine->serialize($request->content);
   $request->content($data);
   
   $class->NEXT::prepare($request);
}

sub receive {
   my ($class, $response) = @_;
   
   $buffer->{$response->id} ||= undef;
   
   my $serialized_data = $response->content;
   
   if ($buffer->{$response->id}) {
        $serialized_data = $buffer->{$response->id}.$response->content;
   }
   
   my $data = $data_encryption->serialize_engine->deserialize($serialized_data);
   
   if ( $@ ) {
        $buffer->{$response->id} .= $response->content;
        $response->content(undef);
   }
   else {
        delete $buffer->{$response->id};
        $response->content($data);
        $class->NEXT::receive($response);
   }   
}

sub spawn {
   my $class = shift;
   unless (defined $data_encryption) {
      $data_encryption = $class->SUPER::new(@_);

      $data_encryption->serialize_engine(Data::Serializer->new());
   }
   $class->NEXT::spawn(@_);   
}


1;

__END__

=head1 AUTHORS

Ed Heil <ed@donorware.com>
Mike Schroeder <mike@donorware.com>
Eriam Schaffter <eriam@cpan.org>

=head1 SEE ALSO

Wx::Data

=cut

# HISTORY:
#
#  $Log: Serializer.pm,v $
#  Revision 1.3  2007/06/01 18:12:00  eriam
#  VICCI Tkt#:0
#  Serializer is passing the test.
#
#  Revision 1.2  2007/05/22 20:10:29  eriam
#  VICCI Tkt#:0
#  + move to NEXT->
#
#  Revision 1.1  2007/05/19 18:27:16  eriam
#  VICCI Tkt#:0
#  new architecture for Wx::Data's cpan realease
#
