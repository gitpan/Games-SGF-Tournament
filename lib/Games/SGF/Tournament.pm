package Games::SGF::Tournament;

use 5.008004;
use strict;
use warnings;
use CGI qw/ :html /;
use Carp qw/ carp /;

our $VERSION = '0.01_02';
$VERSION = eval $VERSION;

sub new {
   my $class = shift;
   my %params = @_;
   $params{sgf_dir} ||= '.';
   $params{base_url} ||= '';
   my %scores;
   my @games;
   undef $/;

   unless (opendir(SGF, $params{sgf_dir})) {
      carp "While opening directory \"$params{sgf_dir}\": $!";
      return undef;
   }
   foreach (grep { /.*\.sgf$/ } readdir SGF) {
      open IN, "$params{sgf_dir}/$_" or next;
      my $sgf_content = <IN>;
      close IN;
      my %game_info = ( file => "$params{base_url}$_" );
      foreach (qw/ RU SZ HA KM PW PB DT TM RE /) {
         if ($sgf_content =~ /$_\[(.*?)\]/) {
            $game_info{$_} = $1;
         } else {
            $game_info{$_} = '?';
         }
      }
      push @games, \%game_info;

      $game_info{RE} =~ /^([BW])\+/o;
      foreach (qw/ PB PW /) {
         $scores{$game_info{$_}} += $1 eq $_ ? 1:0;
      }
   }
   bless { games => \@games, scores => \%scores }, $class;
}

sub games {
   my $self = shift;
   my @rows = TR(
         th('Game#'),
         th('Black'),
         th('White'),
         th('Setup'),
         th('Date'),
         th('Result')
   );
   my $i;

   foreach (sort { $a->{DT} cmp $b->{DT} } @{ $self->{games} }) {
      push @rows, TR(
         td(a({ -href => $_->{file} }, ++$i)),
         td($_->{PB}),
         td($_->{PW}),
         td("$_->{RU}/$_->{SZ}/$_->{HA}/$_->{KM}/$_->{TM}"),
         td($_->{DT}),
         td($_->{RE})
      );
   }

   return table({ -border => 1 },
      caption('Table of played games'),
      @rows
   );
}

sub scores {
   my $self = shift;
   my @rows = TR(
      th('Pos#'),
      th('Name'),
      th('Score')
   );
   my $i;

   foreach (sort { $self->{scores}->{$b} <=> $self->{scores}->{$a} }
      (keys %{ $self->{scores} })
   ) {
      push @rows, TR(
         td(++$i),
         td($_),
         td($self->{scores}->{$_})
      );
   }

   return table({ -border => 1 },
      caption('Scoreboard'),
      @rows
   );
}

1;
__END__

=head1 NAME

Games::SGF::Tournament - Tournament statistics generator class

=head1 SYNOPSIS

   use CGI qw / :html /;
   use Games::SGF::Tournament;
   my $t = Games::SGF::Tournament->new();
   print html(body($t->score()));

=head1 DESCRIPTION

Smart Go Format (SGF) is a file format used to store game records of
two player board games. This module used to collect tournament
information from a set of SGF files and produce statistic HTML tables
for creating WWW tournament pages.

=head1 METHODS

=head2 new

The constructor. Optional parameters are below.

=over 4

=item sgf_dir

Path to SGF files representing the tournament (current directory by
default).

=item base_url

Base URL to prefix file names of SGF files (empty string by default).

=back

=head2 games

Returns a table of played games in chronological order with hyperlinks
to SGF files.

=head2 scores

Returns a table of players descending by score.

=head1 BUGS

This is my very first object-oriented Perl module, and i will 
appreciate any suggestions about OO-style.

Class is tested only on the game of Go. Suggestions about other games 
are welcome, and especially about ties processing.

If two or more players have same score, they position will be
unpredictable. Usually, such a problem on tournaments have to be
resolved with the help of other methods os scoring: SOS and so
on. That is not implemented yet.

=head1 SEE ALSO

L<CGI>, Smart Go Format: L<http://www.red-bean.com/sgf/>.

=head1 AUTHOR

Al Nikolov, E<lt>alnikolov@narod.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Al Nikolov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
USA

=cut
