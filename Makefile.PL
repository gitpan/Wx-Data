#use ExtUtils::MakeMaker;
use inc::Module::Install;

name 'Wx-Data';
author 'Eriam Schaffter <eriam@cpan.org>';
license 'perl';
version_from 'lib/Wx/Data/Manager.pm';
abstract_from 'lib/Wx/Data/Manager.pm';

# Build the prerequisite list
requires 'POE'                   =>   '0.38';
requires 'POE::Loop::Wx'         =>   '0.03';
requires 'Alien::wxWidgets'      =>   0;
requires 'Wx'                    =>   0;
requires 'Class::Inspector'      =>   0;
requires 'Data::Serializer'      =>   0;

build_requires  'POE::Component::Server::SimpleHTTP' => 0;

WriteAll();

