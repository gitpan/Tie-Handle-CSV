package Tie::Handle::CSV;

use 5.006;
use strict;
use warnings;

use Carp;
use Text::CSV_XS;
use Symbol;

use Tie::Handle::CSV::Hash;
use Tie::Handle::CSV::Array;

our $VERSION = '0.05';

sub new
   {
   my $self = gensym();
   return tie(*$self, shift @_, @_) ? $self : ();
   }

sub TIEHANDLE
   {
   my ($class, @opts) = @_;

   my ($file, %opts, $csv_fh);

   ## if an odd number of options are given,
   ## assume the first arg is the file name
   if (@opts % 2)
      {
      $file = shift @opts;
      %opts = @opts;
      $opts{'file'} = $file;
      }
   else
      {
      %opts = @opts;
      }

   ## use 3-arg open if 'openmode' is specified,
   ## otherwise use 2-arg to work with STDIN via '-'
   if ( defined $opts{'openmode'} )
      {
      open( $csv_fh, $opts{'openmode'}, $opts{'file'} )
         || croak "$!: $opts{'file'}";
      }
   else
      {
      open( $csv_fh, $opts{'file'} )
         || croak "$!: $opts{'file'}";
      }

   ## establish the csv object
   ## use given sep_char when possible
   if ( ref $opts{'csv_parser'} ne 'Text::CSV_XS' )
      {
      if (defined $opts{'sep_char'})
         {
         $opts{'csv_parser'} =
            Text::CSV_XS->new( { sep_char => $opts{'sep_char'} } );
         }
      else
         {
         $opts{'csv_parser'} = Text::CSV_XS->new();
         }
      }

   $opts{'header'} = 1 unless exists $opts{'header'};

   if ( $opts{'header'} && ref $opts{'header'} ne 'ARRAY' )
      {
      my $header_line = <$csv_fh>;
      $opts{'csv_parser'}->parse($header_line)
         || croak $opts{'csv_parser'}->error_input();
      $opts{'header'} = [ $opts{'csv_parser'}->fields() ];
      }

   return bless { handle => $csv_fh, opts => \%opts }, $class;

   }

sub READLINE
   {
   my ($self) = @_;

   my $opts = $self->{'opts'};

   if (wantarray)
      {

      my @parsed_lines;

      while (my $parsed_line = $self->READLINE)
         {
         push @parsed_lines, $parsed_line;
         }

      return @parsed_lines;

      }
   else
      {
      my $csv_line = readline($self->{'handle'});
      if (defined $csv_line)
         {
         $opts->{'csv_parser'}->parse($csv_line)
            || croak $opts->{'csv_parser'}->error_input();
         if ( $opts->{'header'} )
            {
            my $parsed_line = Tie::Handle::CSV::HASH->_new($self);
            @{ $parsed_line }{ @{ $opts->{'header'} } }
               = $opts->{'csv_parser'}->fields();
            return $parsed_line;
            }
         else
            {
            my $parsed_line = Tie::Handle::CSV::ARRAY->_new($self);
            @{ $parsed_line } = $opts->{'csv_parser'}->fields();
            return $parsed_line;
            }
         }

      }

      return;

   }

sub CLOSE
   {
   my ($self) = @_;
   close $self->{'handle'};
   }

sub PRINT
   {
   my ($self, @list) = @_;
   my $handle = $self->{'handle'};
   print $handle @list;
   }

sub SEEK
   {
   my ($self, $position, $whence) = @_;
   seek $self->{'handle'}, $position, $whence;
   }

sub TELL
   {
   my ($self) = @_;
   tell $self->{'handle'};
   }

1;
__END__
=head1 NAME

Tie::Handle::CSV - easy access to CSV files

=head1 SYNOPSIS

   use strict;
   use warnings;

   use Tie::Handle::CSV;

   my $csv_fh = Tie::Handle::CSV->new('basic.csv', header => 1);

   while (my $csv_line = <$csv_fh>)
      {
      $csv_line->{'salary'} *= 1.05;  ## give a 5% raise
      print $csv_line, "\n";          ## print new CSV line to STDOUT
      }

   close $csv_fh;

=head1 DESCRIPTION

C<Tie::Handle::CSV> makes basic access to CSV files easier. When you read from
the file handle, a hash reference or an array reference is returned depending
on whether headers exist or do not.

Regardless of the type of the returned data, when it is converted to a string,
it automatically converts back to CSV format.

Assume C<basic.csv> contains.

   name,salary,job
   steve,20000,picker
   dee,19000,checker

File handles can either be tied using the C<tie> builtin...

   tie *CSV_FH, 'Tie::Handle::CSV', 'basic.csv', header => 1;

or by constructing one with the C<new()> method.

   my $csv_fh = Tie::Handle::CSV->new('basic.csv', header => 1);

If either C<tie> or C<new> fail to C<open> the given file, they call
C<Carp::croak> with the value "$!: $file". If you don't wish your program to
fail when a file can't be opened, wrap your instantiation in an C<eval>.

   eval { tie *CSV_FH, 'Tie::Handle::CSV', 'basic.csv', header => 1 };
   my $csv_fh = eval { Tie::Handle::CSV->new('basic.csv', header => 1) };

Once you have successfully tied/instantiated a file, you can read from it as
you normally would.

   my $first_line = <$csv_fh>;

At this point, because the C<header =E<gt> 1> option was given, C<$first_line>
is actually a hash reference, not a string.

   $first_line->{'salary'} *= 1.05;   ## cost of living increase
   print "$first_line->{'name'} => $first_line->{'salary'}\n";

Despite the fact that C<$first_line> is a hash reference, printing it or any
usage as a string, converts it back to CSV format.

   print $first_line, "\n";           ## prints "steve,21000,picker\n"

In the example above, the file has a header, allowing the lines to be treated
as hash references. If it did not have a built in header, the lines could still
be treated as hash references, by passing a list of header names as an argument
to C<tie> or C<new> (see OPTIONS).

If the file did not have a built in header, and no header was passed as an
argument to C<tie> or C<new>, then lines are treated as array references.

   $first_line->[1] *= 1.05;          ## cost of living increase

Printing and string conversion still automatically result in CSV conversion as
with a hash reference.

=head1 OPTIONS

If the number of arguments passed to C<tie> (after the C<Tie::Handle::CSV> name
is given) or C<new> is an odd number, then the first argument is assumed to be
the name of the CSV file. Any remaining arguments are treated as key-value
options pairs.

   tie *CSV_FH, 'Tie::Handle::CSV', 'basic.csv';

   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', header => 1 );

If the number of arguments is even, then all are considered to be key-value
option pairs.

   tie *CSV_FH, 'Tie::Handle::CSV', file => 'basic.csv', header => 1;

   my $csv_fh = Tie::Handle::CSV->new( file => 'basic.csv' );

The following option keys are recognized:

=head2 C<file>

This option specifies the path to the CSV file. If this option is given in
conjunction with an odd number of arguments, the first argument takes
precedence over this option.

   ## same results
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv' );
   my $csv_fh = Tie::Handle::CSV->new( file => 'basic.csv' );

=head2 C<header>

This option indicates whether and how headers are to be used. If this option is
true or non-existent, lines will be represented as hash references. If it is
false, lines will be represented as array references.

   ## no header
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', header => 0 );
   ## print first field of first line
   print +( scalar <$csv_fh> )->[0], "\n";

If this option is true or non-existent, and not an array reference the first
line of the file is read at the time of calling C<tie> or C<new> and used to
define the hash reference keys.

   ## header in file
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv' );
   ## print first field of first line
   print +( scalar <$csv_fh> )->{'name'}, "\n";

If the value for this option B<is> an array reference, the values in the array
reference are used as the keys in the hash reference representing the line of
data.

   ## header passed as arg
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv',
                                        header => [qw/ name salary /] );
   ## print first field of first line
   print +( scalar <$csv_fh> )->{'name'}, "\n";

=head2 C<openmode>

If this option is defined, the value is used as the I<MODE> argument in the
3-arg form of C<open>. Otherwise, the file is opened using 2-arg C<open>.

   ## open in read-write mode
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', openmode => '+<' );

=head2 C<csv_parser>

Internally, L<Text::CSV_XS> is used to do CSV parsing and construction. By
default the L<Text::CSV_XS> instance is instantiated with no arguments. If
other behaviors are desired, you can create your own instance and pass it as
the value to this option.

   ## use colon separators
   my $csv_parser = Text::CSV_XS->new( { sep_char => ':' } );
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv',
                                        csv_parser => $csv_parser );

=head2 C<sep_char>

Perhaps the most common reason for giving the C<csv_parser> option is to
specify a non-comma separator character. For this reason, you can specify a
separator character using the C<sep_char> option. This is passed directly to
the internally created L<Text::CSV_XS> object.

   ## use colon separators
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', sep_char => ':' );

If you specify both the C<sep_char> and C<csv_parser> options, the C<sep_char>
option is ignored.

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::CSV_XS>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Daniel B. Boorstein

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
