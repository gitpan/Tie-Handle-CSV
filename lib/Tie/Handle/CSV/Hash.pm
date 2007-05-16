package Tie::Handle::CSV::Hash;

use 5.006;
use strict;
use warnings;

use overload '""' => \&_stringify, fallback => 1;

sub _new
   {
   my ($class, $parent) = @_;
   my %self;
   tie(%self, $class, $parent);
   bless \%self, $class;
   }

sub TIEHASH
   {
   my ($class, $parent) = @_;
   return bless { data => {}, parent => $parent }, $class;
   }

sub STORE
   {
   my ($self, $key, $value) = @_;
   $self->{'data'}{$key} = $value;
   }

sub FETCH
   {
   my ($self, $key) = @_;
   return $self->{'data'}{$key};
   }

sub EXISTS
   {
   my ($self, $key) = @_;
   exists $self->{'data'}{$key};
   }

sub DELETE
   {
   my ($self, $key) = @_;
   delete $self->{'data'}{$key};
   }

sub CLEAR
   {
   my ($self) = @_;
   %{ $self->{'data'} } = ();
   }

sub FIRSTKEY
   {
   my ($self) = @_;
   $self->{'keys'} = [ @{ $self->{'parent'}{'opts'}{'header'} } ];
   return shift @{ $self->{'keys'} };
   }

sub NEXTKEY
   {
   my ($self) = @_;
   @{ $self->{'keys'} }
      ? return shift @{ $self->{'keys'} }
      : return;
   }

sub _stringify
   {
   my ($self) = @_;
   my $under_tie = tied %$self;
   my @values = @{ $under_tie->{'data'} }
      { @{ $under_tie->{'parent'}{'opts'}{'header'} } };
   $under_tie->{'parent'}{'opts'}{'csv_parser'}->combine(@values)
      || croak $under_tie->{'parent'}{'opts'}{'csv_parser'}->error_input();
   return $under_tie->{'parent'}{'opts'}{'csv_parser'}->string();
   }

1;

__END__

=head1 NAME

Tie::Handle::CSV::Hash - Support class for L<Tie::Handle::CSV>

=cut
