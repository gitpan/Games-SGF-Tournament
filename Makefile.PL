use 5.008004;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Games::SGF::Tournament',
    VERSION_FROM      => 'lib/Games/SGF/Tournament.pm',
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Games/SGF/Tournament.pm',
       AUTHOR         => 'Al Nikolov <alnikolov@narod.ru>') : ()),
);
