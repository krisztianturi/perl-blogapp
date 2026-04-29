package BlogApp::SafeMarkdown;
use strict;
use warnings;
use Text::Markdown 'markdown';
use HTML::Scrubber;

use Exporter 'import';
our @EXPORT_OK = qw(render_content);

my $scrubber = HTML::Scrubber->new;
$scrubber->default(0);
$scrubber->allow(
  qw( p br strong em ul ol li h1 h2 h3 code pre a )
);
$scrubber->rules(
  a => {
    href => qr/^https?:\/\//,
  }
);

sub render_content {
  my ($entity) = @_;
  return $entity unless $entity && $entity->{content};
  my $html = markdown($entity->{content});
  $html = $scrubber->scrub($html);
  $entity->{content_raw} = $entity->{content};
  $entity->{content_html} = $html;
  return $entity;
}
1;
