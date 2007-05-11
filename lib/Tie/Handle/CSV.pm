package Tie::Handle::CSV;

use 5.006;
use strict;
use warnings;

use Carp;
use Text::CSV_XS;
use Symbol;

use Tie::Handle::CSV::Hash;
use Tie::Handle::CSV::Array;

our $VERSION = '0.07';

sub new
   {
   my $self = gensym();
   return tie(*{ $self }, shift @_, @_) ? $self : ();
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

   ## support old 'openmode' option key
   if ( exists $opts{'openmode'} && ! exists $opts{'open_mode'} )
      {
      $opts{'open_mode'} = $opts{'openmode'};
      }

   ## use 3-arg open if 'open_mode' is specified,
   ## otherwise use 2-arg to work with STDIN via '-'
   if ( defined $opts{'open_mode'} )
      {
      open( $csv_fh, $opts{'open_mode'}, $opts{'file'} )
         || croak "$!: $opts{'file'}";
      }
   else
      {
      open( $csv_fh, $opts{'file'} ) || croak "$!: $opts{'file'}";
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

   $opts{'stringify'} = 1 unless exists $opts{'stringify'};

   $opts{'header'} = 1 unless exists $opts{'header'};

   if ( $opts{'header'} )
      {

      if ( ref $opts{'header'} ne 'ARRAY' )
         {
         my $header_line = <$csv_fh>;
         $opts{'csv_parser'}->parse($header_line)
            || croak $opts{'csv_parser'}->error_input();
         $opts{'header'} = [ $opts{'csv_parser'}->fields() ];
         }

      if ( $opts{'force_lower'} )
         {
         for my $header ( @{ $opts{'header'} } )
            {
            $header = lc $header;
            }
         }

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
            my $parsed_line = $opts->{'stringify'}
               ? Tie::Handle::CSV::Hash->_new($self) : {};
            @{ $parsed_line }{ @{ $opts->{'header'} } }
               = $opts->{'csv_parser'}->fields();
            return $parsed_line;
            }
         else
            {
            my $parsed_line = $opts->{'stringify'}
               ? Tie::Handle::CSV::Array->_new($self) : [];
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
   return close $self->{'handle'};
   }

sub PRINT
   {
   my ($self, @list) = @_;
   my $handle = $self->{'handle'};
   return print $handle @list;
   }

sub SEEK
   {
   my ($self, $position, $whence) = @_;
   return seek $self->{'handle'}, $position, $whence;
   }

sub TELL
   {
   my ($self) = @_;
   return tell $self->{'handle'};
   }

1;

__END__

=head1 NAME

Tie::Handle::CSV - easy access to CSV files

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

   use strict;
   use warnings;

   use Tie::Handle::CSV;

   my $csv_fh = Tie::Handle::CSV->new('basic.csv', header => 1);

   while (my $csv_line = <$csv_fh>)
      {
      $csv_line->{'salary'} *= 1.05;  ## give a 5% raise
      print $csv_line, "\n";          ## auto-stringify to CSV line on STDOUT
      }

   close $csv_fh;

=head1 DESCRIPTION

C<Tie::Handle::CSV> makes basic access to CSV files easier.

=head2 Features

=head3 Auto-parse CSV line

When you read from the tied handle, the next line from your CSV is parsed and
returned as a data structure ready for access. In the example below C<$csv_line>
is a hash reference with the column names for keys and the values being the
corresponding data from the second line of the file.

   my $csv_fh = Tie::Handle::CSV->new('foo.csv', header => 1);
   my $csv_line = <$csv_fh>;
   print $csv_line->{'Id'};

In the above example C<$csv_line> is a hash reference because the tied handle
was declared as having a header. If the CSV file does not have a header the line
is parsed and returned as an array reference:

   my $csv_fh = Tie::Handle::CSV->new('bar.csv', header => 0);
   my $csv_line = <$csv_fh>;
   print $csv->[0];

=head3 Auto-stringify to CSV format

When you use the C<$csv_line> in a string context it is automatically
reconstituted as a CSV line.

   print $csv_line, "\n";  ## prints "123,abc,xyz\n"

=head1 EXAMPLES

Assume C<basic.csv> contains:

   name,salary,job
   steve,20000,picker
   dee,19000,checker

The following script uppercases the first letter of everyone's name, increases
their salary by 5% and prints the modified CSV data to STDOUT.

   my $csv_fh = Tie::Handle::CSV->new('basic.csv', header => 1);
   while (my $csv_line = <$csv_fh>)
      {
      $csv_line->{'name'} = ucfirst $csv_line->{'name'};
      $csv_line->{'salary'} *= 1.05;
      print $csv_line . "\n";
      }
   close $csv_fh;

The converted output on STDOUT would appear as:

   Steve,21000,picker
   Dee,19950,checker

=head1 METHODS

=head2 new

   my $csv_fh = Tie::Handle::CSV->new('basic.csv');

The C<new> method returns a tied filehandle. The default options would make the
above equivalent to:

   my $csv_fh = Tie::Handle::CSV->new( csv_parser  => Text::CSV_XS->new(),
                                       file        => 'basic.csv',
                                       force_lower => 0,
                                       header      => 1,
                                       open_mode   => undef,
                                       sep_char    => undef,
                                       stringify   => 1 );

The options to C<new> are discussed in detail below.

=head3 C<csv_parser>

Internally, L<Text::CSV_XS> is used to do CSV parsing and construction. By
default the L<Text::CSV_XS> instance is instantiated with no arguments. If
other behaviors are desired, you can create your own instance and pass it as
the value to this option.

   ## use colon separators
   my $csv_parser = Text::CSV_XS->new( { sep_char => ':' } );
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv',
                                        csv_parser => $csv_parser );

=head3 C<file>

This option specifies the path to the CSV file. As an alternative, the C<file>
key can be omitted. When there are an odd number of arguments the first argument
is taken to be the file name. If this option is given in conjunction with an odd
number of arguments, the first argument takes precedence over this option.

   ## same results
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv' );
   my $csv_fh = Tie::Handle::CSV->new( file => 'basic.csv' );

=head3 C<force_lower>

When this option is true the keys in the hashes returned from line reads are
forced to lowercase. The default value is false, and the keys are not modified
from those in the header.

   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', force_lower => 1 );
   ## print 'Name' value from first line using 'name' key
   my $csv_line = <$csv_fh>;
   print $csv_line->{'name'}, "\n";

=head3 C<header>

This option controls whether headers are to be used. If it is false, lines will
be represented as array references.

   ## no header
   my $csv_fh = Tie::Handle::CSV->new( 'no_header.csv', header => 0 );
   ## print first field of first line
   my $csv_line = <$csv_fh>;
   print $csv_line->[0], "\n";

If this option is true, and not an array reference the values from the first
line of the file are used as the keys in the hash references returned from
subsequent line reads.

   ## header in file
   my $csv_fh = Tie::Handle::CSV->new( 'header.csv' );
   ## print 'name' value from first line
   my $csv_line = <$csv_fh>;
   print $csv_line->{'name'}, "\n";

If the value for this option B<is> an array reference, the values in the array
reference are used as the keys in the hash reference representing the line of
data.

   ## header passed as arg
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv',
                                        header => [qw/ name salary /] );
   ## print 'name' value from first line
   my $csv_line = <$csv_fh>;
   print $csv_line->{'name'}, "\n";

=head3 C<open_mode>

If this option is defined, the value is used as the I<MODE> argument in the
3-arg form of C<open>. Otherwise, the file is opened using 2-arg C<open>.

   ## open in read-write mode
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', open_mode => '+<' );

=head3 C<sep_char>

Perhaps the most common reason for giving the C<csv_parser> option is to
specify a non-comma separator character. For this reason, you can specify a
separator character using the C<sep_char> option. This is passed directly to
the internally created L<Text::CSV_XS> object.

   ## use colon separators
   my $csv_fh = Tie::Handle::CSV->new( 'basic.csv', sep_char => ':' );

If you specify both the C<sep_char> and C<csv_parser> options, the C<sep_char>
option is ignored.

=head3 C<stringify>

If the C<stringify> value is true then lines are returned as tied hash or array
references that auto-stringify back to CSV format. When this option is false
line reads return simple hash or array references. This is intended as an
optimization for faster reads when you don't need to print the line. The default
behavior is stringification.

=head1 AUTHOR

Daniel B. Boorstein, C<< <danboo at cpan.org> >>

=head1 SEE ALSO

L<Text::CSV_XS>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-handle-csv at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Handle-CSV>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Handle::CSV

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Handle-CSV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Handle-CSV>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Handle-CSV>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Handle-CSV>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Daniel B. Boorstein, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
