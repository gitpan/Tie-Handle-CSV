use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Tie::Handle::CSV',
    VERSION_FROM      => 'lib/Tie/Handle/CSV.pm',
    PREREQ_PM         => { Test::More => 0, Text::CSV_XS => 0 },
    $] >= 5.005 ? (AUTHOR => 'Daniel B. Boorstein <danboo@cpan.org>') : (),
);
