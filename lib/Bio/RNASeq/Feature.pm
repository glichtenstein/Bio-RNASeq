package Bio::RNASeq::Feature;

# ABSTRACT:  Represents a Feature from a GFF file

=head1 SYNOPSIS
Represents a Feature from a GFF file
	use Bio::RNASeq::Feature;
	my $file_meta_data_container = Bio::RNASeq::Feature->new(
	  raw_feature => $feature
	  );
=cut

use Moose;

has 'raw_feature'   => ( is => 'rw', isa => 'Bio::SeqFeature::Generic', required   => 1 );

has 'gene_id'       => ( is => 'rw', isa => 'Str',                 lazy_build => 1 );
has 'seq_id'        => ( is => 'rw', isa => 'Str',                 lazy_build => 1 );
has 'gene_strand'   => ( is => 'rw', isa => 'Int',                 lazy_build => 1 );
has 'gene_start'    => ( is => 'rw', isa => 'Int',                 lazy_build => 1 );
has 'gene_end'      => ( is => 'rw', isa => 'Int',                 lazy_build => 1 );
has 'exon_length'   => ( is => 'rw', isa => 'Int',                 lazy_build => 1 );
has 'exons'         => ( is => 'rw', isa => 'ArrayRef',            lazy =>1, builder => '_build_exons' );

has 'locus_tag'     => ( is => 'rw', isa => 'Maybe[Str]',          lazy_build => 1 );
has 'feature_type'  => ( is => 'rw', isa => 'Maybe[Str]',          lazy_build => 1 );
has 'reads_mapping' => ( is => 'rw', isa => 'Bool',                default => 0 );


sub _build_locus_tag
{
  my ($self) = @_;
  my $locus_tag;

  my @junk;
  if($self->raw_feature->has_tag('locus_tag'))
  {
    ($locus_tag, @junk) = $self->raw_feature->get_tag_values('locus_tag');

    $locus_tag =~ s!\"!!g;
  }

  return $locus_tag;
}

sub _build_feature_type
{
  my ($self) = @_;
  my $feature_type;

  if($self->raw_feature->has_tag('locus_tag'))
  {
    $feature_type = $self->raw_feature->primary_tag();
  }
  return $feature_type;
}

sub _build_exons
{
  my ($self) = @_;
  my @exons;
  push @exons, [$self->gene_start, $self->gene_end];
  return \@exons;
}

sub _find_feature_id
{
  my ($self) = @_;
  my $gene_id;
  my @junk;
  my @tag_names = ('ID', 'locus_tag', 'Name', 'Parent');
  
  for my $tag_name (@tag_names)
  {
    if($self->raw_feature->has_tag($tag_name))
    {
      ($gene_id, @junk) = $self->raw_feature->get_tag_values($tag_name);
      return $gene_id;
    }
  }

  return $gene_id;
}

sub _build_gene_id
{
  my ($self) = @_;

  my $gene_id;
  my @junk;
  
  $gene_id = $self->_find_feature_id();
  
  if(! defined($gene_id))
  {
    $gene_id = join("_",($self->seq_id, $self->gene_start, $self->gene_end ));
  }
  $gene_id =~ s/^"|"$//g;

  return $gene_id;
}

sub _build_seq_id
{
  my ($self) = @_;
  $self->raw_feature->seq_id();
}

sub _build_gene_strand
{
  my ($self) = @_;
  $self->raw_feature->strand;
}

sub _build_gene_start
{
  my ($self) = @_;
  $self->raw_feature->start;
}

sub _build_gene_end
{
  my ($self) = @_;
  $self->raw_feature->end;
}

sub _build_exon_length
{
  my ($self) = @_;
  ($self->gene_end - $self->gene_start );
}

sub _filter_out_parent_features_from_exon_list
{
  my ($self) = @_;
  return if(scalar(@{$self->exons}) <= 1);

  my @filtered_exons;

  for my $exon_coords(@{$self->exons})
  {
    if(!($exon_coords->[0] == $self->gene_start && $exon_coords->[1] == $self->gene_end))
    {
      
      push(@filtered_exons, $exon_coords);
    }
  }
  $self->exons(\@filtered_exons);
}

sub _update_exon_length_from_exon_list
{
   my ($self) = @_;
   my $exon_length = 0;
   for my $exon_coords(@{$self->exons})
   {
     $exon_length += ($exon_coords->[1] - $exon_coords->[0]);
   }
   $self->exon_length($exon_length);
   return;
}


sub add_discontinuous_feature
{
  my ($self,$raw_feature, $filter_parents) = @_;
  my $rf_start = $raw_feature->start;
  my $rf_end = $raw_feature->end ;
  push @{$self->exons}, [$rf_start, $rf_end ];
  my $gene_start = ($rf_start < $self->gene_start) ? $rf_start : $self->gene_start;
  my $gene_end = ($rf_end  > $self->gene_end) ? $rf_end : $self->gene_end;

  $self->gene_start($gene_start);
  $self->gene_end($gene_end);
  
  $self->_filter_out_parent_features_from_exon_list() if($filter_parents);
  $self->_update_exon_length_from_exon_list();
  
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

