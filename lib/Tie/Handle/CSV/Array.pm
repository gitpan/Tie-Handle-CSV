package Tie::Handle::CSV::ARRAY;

use 5.006;
use strict;
use warnings;

use overload '""' => \&_stringify, fallback => 1;

sub _new
   {
   my ($class, $parent) = @_;
   my @self;
   tie(@self, $class, $parent);
   bless \@self, $class;
   }

sub TIEARRAY
   {
   my ($class, $parent) = @_;
   return bless { data => [], parent => $parent }, $class;
   }

sub CLEAR
   {
   my ($self) = @_;
   @{ $self->{'data'} } = ();
   }

sub EXTEND
   {
   my ($self, $count) = @_;
   }

sub STORE
   {
   my ($self, $index, $value) = @_;
   $self->{'data'}[$index] = $value;
   }

sub FETCHSIZE
   {
   my ($self) = @_;
   return scalar @{ $self->{'data'} };
   }

sub FETCH
   {
   my ($self, $index) = @_;
   return $self->{'data'}[$index];
   }

sub _stringify
   {
   my ($self) = @_;
   my $under_tie = tied @{ $self };
   my @values = @{ $under_tie->{'data'} };
   $under_tie->{'parent'}{'opts'}{'csv_parser'}->combine(@values)
      || croak $under_tie->{'parent'}{'opts'}{'csv_parser'}->error_input();
   return $under_tie->{'parent'}{'opts'}{'csv_parser'}->string();
   }

1;
