use strict;
use warnings;

use Test::More 'no_plan';
use File::Temp 'tempfile';



## create a temp CSV file

my ($tmp_fh, $tmp_file) = tempfile( UNLINK => 1 );

print $tmp_fh <<EOCSV;
foo,bar,baz
potato,monkey,rutabaga
fred,barney,wilma
EOCSV

close $tmp_fh;


## load module

use_ok('Tie::Handle::CSV');



## NO-HEADER

## test tie interface

ok(! tie(*FH, 'Tie::Handle::CSV', ''),        'tie - bad  - no header' );
ok(  tie(*FH, 'Tie::Handle::CSV', $tmp_file), 'tie - good - no header' );

## test new() interface

my $csv_fh;

ok(! Tie::Handle::CSV->new(''),                  'new - bad  - no header' );
ok(  $csv_fh = Tie::Handle::CSV->new($tmp_file), 'new - good - no header' );

## test reading with no header

my $line1 = <FH>;
my $line2 = <FH>;
my $line3 = <FH>;
my $line4 = <FH>;

ok( ref $line1 eq 'Tie::Handle::CSV::ARRAY',              'tie - ref' );

is( $line1, 'foo,bar,baz',            'tie - line1 - stringify' );
is( $line2, 'potato,monkey,rutabaga', 'tie - line2 - stringify' );
is( $line3, 'fred,barney,wilma',      'tie - line3 - stringify' );
is( $line4, undef,                    'tie - line4 - undef' );

is( $line1->[0], 'foo', 'tie - line1 - 0' );
is( $line1->[1], 'bar', 'tie - line1 - 1' );
is( $line1->[2], 'baz', 'tie - line1 - 2' );
is( $line1->[3], undef, 'tie - line1 - 3' );

is( $line2->[0], 'potato',   'tie - line2 - 0' );
is( $line2->[1], 'monkey',   'tie - line2 - 1' );
is( $line2->[2], 'rutabaga', 'tie - line2 - 2' );
is( $line2->[3], undef,      'tie - line2 - 3' );

is( $line3->[0], 'fred',   'tie - line3 - 0' );
is( $line3->[1], 'barney', 'tie - line3 - 1' );
is( $line3->[2], 'wilma',  'tie - line3 - 2' );
is( $line3->[3], undef,    'tie - line3 - 3' );

$line1 = <$csv_fh>;
$line2 = <$csv_fh>;
$line3 = <$csv_fh>;
$line4 = <$csv_fh>;

ok( ref $line1 eq 'Tie::Handle::CSV::ARRAY',              'new - ref' );

ok( $line1 eq 'foo,bar,baz',            'new - line1 - stringify' );
ok( $line2 eq 'potato,monkey,rutabaga', 'new - line2 - stringify' );
ok( $line3 eq 'fred,barney,wilma',      'new - line3 - stringify' );
ok(! defined $line4,                    'new - line4 - undef' );

is( $line1->[0], 'foo', 'new - line1 - 0' );
is( $line1->[1], 'bar', 'new - line1 - 1' );
is( $line1->[2], 'baz', 'new - line1 - 2' );
is( $line1->[3], undef, 'new - line1 - 3' );

is( $line2->[0], 'potato',   'new - line2 - 0' );
is( $line2->[1], 'monkey',   'new - line2 - 1' );
is( $line2->[2], 'rutabaga', 'new - line2 - 2' );
is( $line2->[3], undef,      'new - line2 - 3' );

is( $line3->[0], 'fred',   'new - line3 - 0' );
is( $line3->[1], 'barney', 'new - line3 - 1' );
is( $line3->[2], 'wilma',  'new - line3 - 2' );
is( $line3->[3], undef,    'new - line3 - 3' );

ok( close(FH),      'tie - close' );
ok( close($csv_fh), 'new - close' );

