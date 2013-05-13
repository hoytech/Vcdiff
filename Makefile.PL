use strict;

use ExtUtils::MakeMaker;


use Alien::OpenVcdiff;
 
my $openvcdiff = Alien::OpenVcdiff->new;
 
my $libs = $openvcdiff->libs;
my $cflags = $openvcdiff->cflags;

if ($cflags =~ m{^-I\S*google/?$}) {
  $cflags .= '/../';
} else {
  die "Unexpected value from Alien::OpenVcdiff::cflags: $cflags";
}


my %args = (
    NAME              => 'Vcdiff',
    VERSION_FROM      => 'lib/Vcdiff.pm',
    XSOPT             => '-C++',
    CC                => 'g++',
    CCFLAGS           => $cflags,
    LIBS              => $libs,
    PREREQ_PM => {
      'Alien::OpenVcdiff' => 0,
    },
    OBJECT            => 'Vcdiff.o',
    LICENSE           => 'perl',
    dist => {
      PREOP => 'perldoc -uT $(VERSION_FROM) > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Vcdiff.git',
            bugtracker => 'https://github.com/hoytech/Vcdiff/issues',
        },
    };
}

WriteMakefile(%args);
