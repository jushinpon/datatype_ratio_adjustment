use strict;
use warnings;
use POSIX;
use List::Util qw(shuffle);

my $rm_type = 2;#type you want to remove
my @ratio = (15,20,25,30,35,40,45);
my $template = "1.data";

my $atomn = `grep atoms ./$template|awk '{print \$1}'`;
$atomn =~ s/^\s+|\s+$//g;

my $typen = `grep types ./$template|awk '{print \$1}'`;
$typen =~ s/^\s+|\s+$//g;

my @atominfo = `grep -v '^[[:space:]]*\$' ./$template|grep -A $atomn Atoms|grep -v Atoms|grep -v -- '--'`;
map { s/^\s+|\s+$//g; } @atominfo;

my @massinfo = `grep -v '^[[:space:]]*\$' ./$template|grep -A $typen Masses|grep -v Masses|grep -v -- '--'`;
map { s/^\s+|\s+$//g; } @massinfo;
my $masses = join("\n",@massinfo);
#chomp $masses;

my @cellinfo = ` grep -e lo -e xy ./$template`;
map { s/^\s+|\s+$//g; } @cellinfo;
die "Cell information is wrong!" unless(@cellinfo);
my $cellInfo = join("\n",@cellinfo);
chomp $cellInfo;

my @rm_id;#all atom ids could be removed.

for my $i (@atominfo){
    my @temp = (split(/\s+/,$i));
    if($temp[1] == $rm_type){#type id
        push @rm_id,$temp[0];#atom id
    }
}

my $tot_rm = @rm_id; #total atoms could be removed!

for my $d (@ratio){
    my $rm_number = $tot_rm - int(($d/100.0)* $tot_rm);#atom number to keep  
    my @rm_id = shuffle(@rm_id);
    my @removed = @rm_id[0 .. $rm_number - 1];#slice
    my $counter = 0;#atoms left
    my @left;
    for my $i (@atominfo){
        my @temp = (split(/\s+/,$i));
        unless($temp[0] ~~ @removed){#type id
            $counter++;
            my $temp = "$counter " . "@temp[1..$#temp]";
            chomp $temp;
            push @left,$temp;
        }
    }
    my $coords = join("\n",@left);
    chomp $coords;

my $here_doc =<<"END_MESSAGE";
# LAMMPS data file written by OVITO Basic 3.5.4
$counter atoms
$typen atom types

$cellInfo

Masses

$masses

Atoms  

$coords
END_MESSAGE

    unlink "./p$d.data";
    open(my $FH, "> ./p$d.data") or die $!;
    print $FH $here_doc;
    close($FH);
}
