package Vcdiff;

use strict;

use Alien::OpenVcdiff;

our $VERSION = '0.100';
$VERSION = eval $VERSION;

require DynaLoader;
our @ISA = 'DynaLoader';
__PACKAGE__->bootstrap($VERSION);

1;


__END__


=head1 NAME

Vcdiff - diff and patch for binary data

=head1 SYNOPSIS

    use Vcdiff;

    my $delta = Vcdiff::diff($source, $target);

    ## ... send the $delta string to someone who has $source ...

    my $target2 = Vcdiff::patch($source, $delta);

    ## $target2 is the same as $target



=head1 DESCRIPTION

Given a source string and a target string, the C<Vcdiff::diff> function computes another string called a delta that encodes the information needed to turn source into target.

Anyone who has source and delta can compute target with the C<Vcdiff::patch> function.

If the source and target inputs are related, delta can theoretically be very small relative to target, meaning it may be more efficient to send the delta string instead of the whole target.

Even though source and target don't necessarily have to be binary data (regular data is fine too), the delta string will always contain binary data including NUL bytes so if your transport protocols don't support this you will have to encode or escape it in some way (ie Base64). Compressing the delta before you do this might be worthwhile depending on the size of your changes and the entropy of your data.

This module uses a backend library to implement L<RFC 3284|http://www.faqs.org/rfcs/rfc3284.html>, "The VCDIFF Generic Differencing and Compression Data Format". Currently the only library supported is L<open-vcdiff|http://code.google.com/p/open-vcdiff/> but the thinking behind the L<Vcdiff> namespace is that it could become "the DBI" of VCDIFF implementations.


=head1 OPEN-VCDIFF

Currently this module always uses L<Alien::OpenVcdiff> which is a module that configures, builds, and installs Google's L<open-vcdiff|http://code.google.com/p/open-vcdiff/> library.

The alien package installs the C<vcdiff> binary for your convenience but this module uses the C<libvcdenc.so> and C<libvcddec.so> shared libraries so that the diffing computation is done in-process and no processes are forked.

Once I have finished the streaming API implementation I will also document some limitations and how to use memory mapped files from perl so as to mostly alleviate them. If I understand correctly, even with the streaming API C<open-vcdiff> has a hard upper-limit of 2G file sizes and the default (which this module hasn't changed) is 64M so be warned. 


=head1 TODO

Implement the streaming API and possibly the re-usable "hashed dictionary" API.

Create an alien package for L<xdelta3|http://xdelta.org/> and a way to use that instead.


=head1 SEE ALSO

L<Vcdiff github repo|https://github.com/hoytech/Vcdiff>

L<RFC 3284|http://www.faqs.org/rfcs/rfc3284.html>, "The VCDIFF Generic Differencing and Compression Data Format"

L<Alien::OpenVcdiff>

L<open-vcdiff|http://code.google.com/p/open-vcdiff/>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut




    $str = Vcdiff::diff($str, $str);
    $str = Vcdiff::diff($str, $fd);
    ?? Vcdiff::diff($str, $str, $fd);
    ?? Vcdiff::diff($str, $fd, $fd);

    $str = Vcdiff::patch($str, $str);
    $str = Vcdiff::patch($str, $fd);
    ?? Vcdiff::patch($str, $str, $fd);
    ?? Vcdiff::patch($str, $fd, $fd);
