package Vcdiff;

use strict;

use Symbol;
use Carp;

our $VERSION = '0.100';


## This variable indicates what backend should be used. It should
## be a package name such as "Vcdiff::Xdelta3".

our $backend;


## When new backends are added, this should be updated so that
## the new backend will be probed for when none are already loaded.

our @known_backends = qw(
  Vcdiff::Xdelta3
  Vcdiff::OpenVcdiff
);


## These packages should be skipped when looking for a backend
## because they are internal to this distribution and share the
## Vcdiff namespace. In hindsight it might have been a good idea
## to give the backends their own namespace such as Vcdiff::Backend.

my @internal_packages = qw (
  Test
);



sub diff {
  load_backend();

  {
    no strict "refs";
    return qualify("diff", $backend)->(@_);
  }
}

sub patch {
  load_backend();

  {
    no strict "refs";
    return qualify("patch", $backend)->(@_);
  }
}


sub load_backend {
  ## If a backend is set, make sure it is loaded:

  if (defined $backend) {
    eval "require $backend";
    croak $@ if $@;
    return;
  }

  ## If a backend has already been loaded but not set, set it:

  foreach my $k (keys %INC) {
    if ($k =~ m{^Vcdiff/([^.]+)}) {
      my $pm = $1;
      next if grep { $pm eq $_ } @internal_packages;
      $backend = "Vcdiff::$pm";
      return;
    }
  }

  ## Try to find a suitable backend then load and set it:

  foreach my $backend_candidate (@known_backends) {
    eval "require $backend_candidate";

    if (!$@) {
      $backend = $backend_candidate;
      return;
    }
  }

  croak "Unable to find any Vcdiff backend modules (see perldoc Vcdiff)";
}

1;



__END__


=head1 NAME

Vcdiff - diff and patch for binary data

=head1 SYNOPSIS

B<In order to use this module you must install one or more backend modules (see below)>

    use Vcdiff;

    my $delta = Vcdiff::diff($source, $target);

    ## ... send the $delta string to someone who has $source ...

    my $target2 = Vcdiff::patch($source, $delta);

    ## $target2 is the same as $target



=head1 DESCRIPTION

Given source data and target data, the C<Vcdiff::diff> function computes a "delta" that encodes the information needed to turn source into target.

Anyone who has source and delta can compute target with the C<Vcdiff::patch> function.

If the source and target inputs are related then delta can be very small relative to target, meaning it may be more efficient to send the delta string instead of the whole target.

Even though source and target don't necessarily have to be binary data (regular data is fine too), the delta will always contain binary data including NUL bytes so if your transport protocols don't support this you will have to encode or escape it in some way (ie Base64). Compressing the delta before you do this might be worthwhile depending on the size of your changes and the entropy of your data.

The delta format is described by L<RFC 3284|http://www.faqs.org/rfcs/rfc3284.html>, "The VCDIFF Generic Differencing and Compression Data Format".


=head1 STREAMING API

The streaming API is sometimes more convenient than the in-memory API. It can also be more efficient since it uses less memory. Also, you can start processing output before Vcdiff has finished.

Sometimes you have to use the streaming API in order to handle files that are too large to fit into your virtual address space (though note that some backends have size limitations apart from this).

In order to send output to a stream, a file handle should be passed in as the 3rd argument to C<diff> or C<patch>:

    Vcdiff::diff("hello", "hello world", \*STDOUT);

In order to fully take advantage of streaming, the source and target parameters of C<diff> and the source and delta parameters of C<patch> can be file handles instead of strings:

    open(my $source_fh, '<', 'source.dat') || die $!;
    open(my $target_fh, '<', 'target.dat') || die $!;
    open(my $delta_fh, '>', 'delta.dat') || die $!;

    Vcdiff::diff($source_fh, $target_fh, $delta_fh);

Note that in all current backends the source file handle must be backed by an C<lseek(2)>able and/or C<mmap(2)>able file descriptor (in other words, a real file, not a pipe or socket). Vcdiff will throw an exception if the source file handle is unsuitable.



=head1 MEMORY MAPPED INPUTS

If the source or target/delta data is in a file, an alternative to the streaming API is to map the files into memory with C<mmap(2)> and then pass the mappings in to C<diff>/C<patch> as strings.

Doing so is more efficient than the streaming API for large files because fewer system calls are made and a kernel-space to user-space copy is avoided. As mentioned above, files that are too large to fit in your virtual address must be diffed with the streaming API (this is only an issue when diffing multi-gigabyte files on 32 bit systems).

Here is an example using L<Sys::Mmap>:

    use Sys::Mmap;

    open(my $source_fh, '<', 'source.dat') || die $!;
    open(my $target_fh, '<', 'target.dat') || die $!;
    open(my $delta_fh, '>', 'delta.dat') || die $!;

    my ($source_str, $target_str);

    mmap($source_str, 0, PROT_READ, MAP_SHARED, $source_fh) || die $!;
    mmap($target_str, 0, PROT_READ, MAP_SHARED, $target_fh) || die $!;

    Vcdiff::diff($source_str, $target_str, $delta_fh);

    munmap($source_str);
    munmap($target_str);



=head1 BACKENDS

L<Vcdiff> doesn't itself implement delta compression. Instead, it provides a consistent interface to various open-source VCDIFF (RFC 3284) implementations. The implementation libraries it interfaces to are called "backends".

In other words, L<Vcdiff> aims to be "the DBI" of VCDIFF implementations.

The currently supported backends are described below. See the POD documentation in the backend module distributions for more details on the pros and cons of each backend.


=head2 XDELTA3 BACKEND

The L<Vcdiff::Xdelta3> backend module bundles Joshua MacDonald's L<Xdelta3|http://xdelta.org/> library.


=head2 OPEN-VCDIFF BACKEND

The L<Vcdiff::OpenVcdiff> backend module depends on L<Alien::OpenVcdiff> which configures, builds, and installs Google's L<open-vcdiff|http://code.google.com/p/open-vcdiff/> library.


=head2 FUTURE BACKENDS

Another possible candidate would be Kiem-Phong Vo's L<Vcodex|http://www2.research.att.com/~gsf/download/ref/vcodex/vcodex.html> library which contains a vcdiff implementation.

A really cool project would be a pure-perl VCDIFF implementation that could be used in environments that are unable to compile XS modules.


=head2 CHOOSING A BACKEND

In order to choose which backend to use, L<Vcdiff> will first check to see if the C<$Vcdiff::backend> variable is populated. If so, it will attempt to load that backend. This variable can be used to force a particular backend:

    {
        local $Vcdiff::backend = 'Vcdiff::OpenVcdiff';
        $delta = Vcdiff::diff($source, $target);
    }

Otherwise, L<Vcdiff> will check to see if any backends have been loaded already. If so, it will choose the first one it finds:

    use Vcdiff::Xdelta3;
    $delta = Vcdiff::diff($source, $target);

If it doesn't find any loaded backends, it will try to load them in the following order: Xdelta3, OpenVcdiff. 

Finally, if none of these backends can be loaded, an exception is thrown.





=head1 SEE ALSO

L<Vcdiff github repo|https://github.com/hoytech/Vcdiff>

L<RFC 3284|http://www.faqs.org/rfcs/rfc3284.html>, "The VCDIFF Generic Differencing and Compression Data Format"


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
