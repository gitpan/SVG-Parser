use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'SVG::Parser',
    'AUTHOR'            => 'Peter Wainwright, peter.wainwright@cybrid.net',
    'VERSION_FROM'	=> 'Parser.pm',
    'ABSTRACT_FROM'     => 'Parser.pm',
    'PREREQ_PM'		=> { SVG => 2.0 }, 
);
