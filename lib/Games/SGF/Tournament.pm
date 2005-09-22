package Games::SGF::Tournament;

use version; $VERSION = qv('1.1_2');
use warnings;
use strict;
use Carp;
use CGI qw/ :html /;
use Parse::RecDescent;

sub new {
   my $class = shift;
   my %params = @_;
   $params{sgf_dir} = '.' unless defined $params{sgf_dir};
   $params{base_url} = '' unless defined $params{base_url};
   my @games;
   undef $/;

   unless (opendir(SGF, $params{sgf_dir})) {
      carp "While opening directory \"$params{sgf_dir}\": $!";
      return undef;
   }
   
   my $parser = Parse::RecDescent->new(q<
      { my %info }
      SGF:        GameTree { $return = \%info }
      GameTree:   '(' Node(s) GameTree(s?) ')'
      Node:       ';' Property(s?)
      Property:   PropIdent PropValue(s) {
                     $info{$item{PropIdent}} = 
                        join ';', @{$item{'PropValue(s)'}} 
                           if grep $item{PropIdent} eq $_, 
                              qw/ RU SZ HA KM PW PB DT TM RE /;
                  }
      PropIdent:  /[[:alnum:]]+/o { 
                     ($return = $item[1]) =~ s/[^[:upper:]\d]//go;
                  }
      PropValue:  '[' Character(s?) ']' { 
                     $return = join '', @{$item{'Character(s?)'}} 
                  }
      Character:  /[^\\\\\]]+/so | Escaped
      Escaped:    '\\\\' | '\]' { $return = substr $item[1], 1 }
   >);
   
   foreach (grep { /.*\.sgf$/io } readdir SGF) {
      open IN, "$params{sgf_dir}/$_" or next;
      my %info = %{$parser->SGF(<IN>)};
      foreach (qw/ RU SZ HA KM PW PB DT TM RE /) {
         $info{$_} = '' unless defined $info{$_};
      }
      $info{file} = "$params{base_url}$_" ;
      push @games, \%info;
   }
     
   bless { _games => \@games }, $class;
}

sub games {
   my $self = shift;
   my %params = @_;
   $params{cgi}->{border} = '1' unless defined $params{cgi}->{border};
   $params{caption} = 'Played games' unless defined $params{caption};
   my @rows = TR(
         th('Game#'),
         th('Black'),
         th('White'),
         th('Setup'),
         th('Date'),
         th('Result')
   );
   
   my $i;
   foreach (sort { $a->{DT} cmp $b->{DT} } @{$self->{_games}}) {
      push @rows, TR(
         td(a({ -href => $_->{file} }, ++$i)),
         td($_->{PB}),
         td($_->{PW}),
         td("$_->{RU}/$_->{SZ}/$_->{HA}/$_->{KM}/$_->{TM}"),
         td($_->{DT}),
         td($_->{RE})
      );
   }
   
   table($params{cgi}, caption($params{caption}), @rows);
}

sub scores {
   my $self = shift;
   my %params = @_;
   $params{cgi}->{border} = '1' unless defined $params{cgi}->{border};
   $params{caption} = 'Scoreboard' unless defined $params{caption};
   my @rows = TR(
      th('Pos#'),
      th('Name'),
      th('Score')
   );
   my %scores;

   foreach my $info (@{$self->{_games}}) {
      $info->{RE} =~ /^([BW])\+/o;
      foreach (qw/ B W /) {
         $scores{$info->{"P$_"}} += $1 eq $_ ? 1:0;
      }
   }   
   
   my $i;
   foreach (sort { $scores{$b} <=> $scores{$a} } keys %scores) {
      push @rows, TR(
         td(++$i),
         td($_),
         td($scores{$_})
      );
   }

   table($params{cgi}, caption($params{caption}), @rows);
}

1;

__END__

=head1 NAME

B<Games::SGF::Tournament> - Tournament statistics generator


=head1 VERSION

This document describes B<Games::SGF::Tournament> version 1.1


=head1 SYNOPSIS

    use CGI qw / :html /;
    use Games::SGF::Tournament;
    my $t = Games::SGF::Tournament->new();
    print html(body($t->scores()));

=head1 DESCRIPTION

SGF is acronym for Smart Game File and is a file format used to store game
records of two player board games. This module used to collect game information
from a set of SGF files and produce HTML tables for creating WWW tournament
pages.


=head1 INTERFACE

B<Games::SGF::Tournament> is a class with following methods:

=head2 new

The constructor. Optional parameters are:

=over

=item I<sgf_dir>

Path to SGF files representing the tournament. Default: C<'.'>.

=item I<base_url>

Base URL to prefix file names of SGF files. Default: C<''>.

=back

=head2 games

Returns a table of played games in chronological order with hyperlinks
to SGF files. Optional parameters are:

=over

=item I<cgi>

The hash reference passed directly to L<CGI> as C<< <table> >> attributes.
Default: C<< { border => '1' } >>.

=item I<caption>

The table caption. Default: C<'Played Games'>.

=back

=head2 scores

Returns a table of players descending by score. Optional parameters are:

=over

=item I<cgi>

The hash reference passed directly to L<CGI> as C<< <table> >> attributes.
Default: C<< { border => '1' } >>.

=item I<caption>

The table caption. Default: C<'Scoreboard'>.

=back


=head1 DIAGNOSTICS

=over

=item C<While opening directory "dir": os-error>

Can't open given I<sgf_dir> for reading. Probably it doesn't exist or have
inappropriate permissions, see OS error message.

=back


=head1 CONFIGURATION AND ENVIRONMENT

B<Games::SGF::Tournament> requires no configuration files or environment
variables.


=head1 DEPENDENCIES

=over

=item L<version>

=item L<Parser::RecDescent>

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

The class should be compatible to C<FF[3]> and C<GM[1]>, only the first game
tree per file is significant (mostly because i cannot realise what actually for
a collection of games stored in one file). Suggestions welcome.

If two or more players have same score, they positions will be
unpredictable. Usually, such a problem on tournaments have to be
resolved with the help of other methods os scoring: SOS and so
on. That is not implemented yet.

This is my very first object-oriented Perl module, and i will 
appreciate any suggestions about OO-style.

Please report any bugs or feature requests through the web interface at
L<http://sourceforge.net/tracker/?group_id=143987>.


=head1 SEE ALSO

L<CGI>, Smart Game File: L<http://www.red-bean.com/sgf/>.


=head1 AUTHOR

Al Nikolov E<lt>alnikolov@narod.ruE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Al Nikolov E<lt>alnikolov@narod.ruE<gt>. All rights
reserved.

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


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=cut
