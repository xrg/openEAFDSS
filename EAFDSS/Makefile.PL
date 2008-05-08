use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'EAFDSS::Base',
    VERSION_FROM      => 'lib/EAFDSS/Base.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/EAFDSS/Base.pm', # retrieve abstract from module
       AUTHOR         => 'Hasiotis Nikos (hasiotis@gmail.com)') : ()),
);
