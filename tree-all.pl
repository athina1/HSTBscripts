#/bin/perl/

use strict;
use warnings;
use File::Path qw(make_path);

my @molecs = (
   # dir_tree( 'AC', 6, 1, 1 ),
   # dir_tree( 'AT', 6, 1, 24 ),
   # dir_tree( 'MC', 6, 11, 29 ),
   # dir_tree( 'MT', 6, 1, 22 ),
   # dir_tree( 'KC', 6, 3, 28 ),
    dir_tree( 'KT', 6, 8, 22 ),
);

#my @frames = (
#   dir_tree( 'F', 6, 1, 100 ),
#);

for my $molecs (@molecs) {
    #for my $frames (@frames) {
    make_path "/home/wcg/RESULTS/$molecs";
    #} 
}


sub dir_tree {
    my ( $name, $total_length, $from, $to ) = @_;

    my $length = $total_length - length($name);
    my $format = "${name}%0${length}d";

    return map sprintf( $format, $_ ), $from .. $to;
}
