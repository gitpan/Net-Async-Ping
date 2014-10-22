package Net::Async::Ping::TCP;
$Net::Async::Ping::TCP::VERSION = '0.001000';
use Moo;
use warnings NONFATAL => 'all';

use Future;
use POSIX 'ECONNREFUSED';
use Time::HiRes;

use namespace::clean;

has default_timeout => (
   is => 'ro',
   default => 5,
);

has service_check => ( is => 'rw' );

has bind => ( is => 'rw' );

has port_number => (
   is => 'rw',
   default => 7,
);

sub ping {
   my ($self, $loop, $host, $timeout) = @_;
   $timeout ||= $self->default_timeout;

   my $service_check = $self->service_check;

   my $t0 = [Time::HiRes::gettimeofday];

   return Future->wait_any(
      $loop->connect(
         host     => $host,
         service  => $self->port_number,
         socktype => 'stream',
         ($self->bind ? (
            local_host => $self->bind,
         ) : ()),
      ),
      $loop->timeout_future(after => $timeout)
   )
   ->then(
      sub { Future->wrap(Time::HiRes::tv_interval($t0)) },
      sub {
         my ($human, $layer) = @_;
         my $ex    = pop;
         if ($layer eq 'connect') {
            return Future->wrap(Time::HiRes::tv_interval($t0))
               if !$service_check && $ex == ECONNREFUSED;
         }
         Future->new->die(Time::HiRes::tv_interval($t0))
      },
   )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping::TCP

=head1 VERSION

version 0.001000

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
