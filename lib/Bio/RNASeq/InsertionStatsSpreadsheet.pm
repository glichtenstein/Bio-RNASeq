package Bio::RNASeq::InsertionStatsSpreadsheet;

# ABSTRACT: Builds a spreadsheet of insertion results

=head1 SYNOPSIS
Builds a spreadsheet of insertion results
	use Bio::RNASeq::InsertionStatsSpreadsheet;
	my $expression_results = Bio::RNASeq::ExpressionStatsSpreadsheet->new(
	  output_filename => '/abc/my_results.csv',
	  );
	$expression_results->add_result($my_rpkm_values);
	$expression_results->add_result($more_rpkm_values);
	$expression_results->build_and_close();

=cut

use Moose;
extends 'Bio::RNASeq::CommonSpreadsheet';

sub _result_rows
{
  my ($self) = @_;
  my @denormalised_results;
  for my $result_set (@{$self->_results})
  {
    push(@denormalised_results, 
      [
      $result_set->{seq_id},
      $result_set->{gene_id},
      $result_set->{normalised_pos_insert_sites},
      $result_set->{pos_insert_sites},
      $result_set->{normalised_neg_insert_sites},
      $result_set->{neg_insert_sites},
      $result_set->{normalised_zero_insert_sites},
      $result_set->{zero_insert_sites},
      $result_set->{normalised_total_insert_sites},
      $result_set->{total_insert_sites},
      $result_set->{normalised_pos_insert_site_reads},
      $result_set->{pos_insert_site_reads},
      $result_set->{normalised_neg_insert_site_reads},
      $result_set->{neg_insert_site_reads},
      $result_set->{normalised_zero_insert_site_reads},
      $result_set->{zero_insert_site_reads},
      $result_set->{normalised_total_insert_site_reads},
      $result_set->{total_insert_site_reads},
    ]);

  }
  return \@denormalised_results;
}

sub _header
{
  my ($self) = @_;
  my @header;
  @header = ["Seq ID","GeneID", 
  'Normalised pos insert sites', 'Pos insert sites',
  'Normalised neg insert sites', 'Neg insert sites', 
  'Normalised unknown strand insert sites', 'Unknown strand insert sites', 
  'Normalised total insert sites', 'Total insert sites', 
  'Normalised pos insertions', 'Pos insertions',
  'Normalised neg insertions', 'Neg insertions', 
  'Normalised unknown strand insertions', 'Unknown strand insertions', 
  'Normalised total insertions', 'Total insertions',
  ];  
  return \@header;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
