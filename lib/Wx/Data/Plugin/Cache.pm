package Wx::Data::Plugin::Cache;

use strict;
use warnings;

require Cache::FileCache;
import Cache::FileCache;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(
   qw/namespace default_expires_in cache_root cache_engine/
);

my $data_cache;

sub spawn {	
   my $class = shift;
   
   unless (defined $data_cache) {
      $data_cache = $class->SUPER::new(@_);
   }
   
   $data_cache->namespace('_default_cache_')
      unless defined $data_cache->namespace;

   $data_cache->default_expires_in(600)
      unless defined $data_cache->default_expires_in;   

   $data_cache->cache_engine(
      Cache::FileCache->new({
         namespace            => $data_cache->namespace,
         default_expires_in   => $data_cache->default_expires_in,
         cache_root           => $data_cache->cache_root
      })
   );
   
   $class->NEXT::spawn(@_);
}

sub prepare {
   my ($class, $request) = @_;
   
   my $response = $data_cache->cache_engine->get( $request->id );
   
   if (defined $response) {
      $class->distribute_data($response);
      $request->is_valid(0);
   }
   else {
      $class->NEXT::prepare($request);
   }
}

sub receive {
   my ($class, $response) = @_;
   
   $data_cache->cache_engine->set( $response->id, $response );
   
   $class->NEXT::receive($response);
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
#  $Log: Cache.pm,v $
#  Revision 1.5  2007/06/01 17:55:59  eriam
#  VICCI Tkt#:0
#  Cache is working.
#
#  Revision 1.4  2007/05/31 19:22:36  eriam
#  VICCI Tkt#:0
#  The cache plugin is now working.
#
#  Revision 1.3  2007/05/22 20:10:29  eriam
#  VICCI Tkt#:0
#  + move to NEXT->
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
