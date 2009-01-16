use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'EAFDSS',
    VERSION_FROM      => 'lib/EAFDSS.pm',
    PREREQ_PM         => {
		"Switch"           => 2.10,
		"Carp"             => 1.04,
		"Socket"           => 1.78,
		"Class::Base"      => 0.03,
		"IO::Socket::INET" => 1.31,
		"Time::HiRes"      => 1.86,
		"Digest::SHA1"     => 2.11,
		"Config::IniHash"  => 3.00
	 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/EAFDSS.pm', # retrieve abstract from module
       AUTHOR         => 'Hasiotis Nikos (hasiotis@gmail.com)') : ()),
);
