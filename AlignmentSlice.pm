=head1 NAME

AlignmentSlice.pm   - Extract a slice of reads for a sequence file within a specific region

=head1 SYNOPSIS

use Pathogens::RNASeq::AlignmentSlice;
my $alignment_slice = Pathogens::RNASeq::AlignmentSlice->new(
  filename => '/abc/my_file.bam',
  window_margin => 10,
  total_mapped_reads => 1234,
  );
  my %rpkm_values = $alignment_slice->rpkm_values;
  $rpkm_values{rpkm_sense};
  $rpkm_values{rpkm_antisense};
  $rpkm_values{mapped_reads_sense};
  $rpkm_values{mapped_reads_antisense};

=cut
package Pathogens::RNASeq::AlignmentSlice;
use Moose;
use Pathogens::RNASeq::Exceptions;
use Pathogens::RNASeq::Read;


has 'filename'           => ( is => 'rw', isa => 'Str',                       required   => 1 );
has 'feature'            => ( is => 'rw', isa => 'Pathogens::RNASeq::Feature', required   => 1 );
has 'window_margin'      => ( is => 'rw', isa => 'Int',                       default    => 50 );
has 'total_mapped_reads' => ( is => 'rw', isa => 'Int',                       required   => 1 );
has 'rpkm_values'        => ( is => 'rw', isa => 'HashRef',                   lazy_build => 1 );

has '_input_slice_filename' => ( is => 'rw', isa => 'Str'); # allow for testing and for using VR samtools view output file
has '_slice_file_handle' => ( is => 'rw',  lazy_build   => 1 );
has '_window_start'      => ( is => 'rw', isa => 'Int', lazy_build   => 1 );
has '_window_end'        => ( is => 'rw', isa => 'Int', lazy_build   => 1 );

sub _build__window_start
{
  my ($self) = @_;
  my $window_start = $self->feature->gene_start - $self->window_margin;
  $window_start = $window_start < 1 ? 1 : $window_start;
  return $window_start;
}

sub _build__window_end
{
  my ($self) = @_;
  $self->feature->gene_end + $self->window_margin;
}

sub _build__slice_file_handle
{
  my ($self) = @_;
  my $slice_file_handle;
  open($slice_file_handle, $self->_slice_stream ) || Pathogens::RNASeq::Exceptions::FailedToOpenAlignementSlice->throw( error => "Cant view slice for ".$self->filename." ".$self->_window_start." " .$self->_window_end );
  return $slice_file_handle;
}

sub _slice_stream
{
  my ($self) = @_;
  if($self->_input_slice_filename)
  {
    return $self->_input_slice_filename;
  }
  else
  {
    return "samtools view ".$self->filename." ".$self->feature->seq_id.":".$self->_window_start."-".$self->_window_end." |"; 
  }
}

sub _build_rpkm_values
{
  my ($self) = @_;
  my %rpkm_values;
  
  $rpkm_values{mapped_reads_sense} = 0;
  $rpkm_values{mapped_reads_antisense} = 0;
  my $file_handle = $self->_slice_file_handle;
  
  while(my $line = <$file_handle>)
  {
    my $mapped_reads = Pathogens::RNASeq::Read->new(alignment_line => $line, exons => $self->feature->exons, gene_strand => $self->feature->gene_strand )->mapped_reads;
    $rpkm_values{mapped_reads_sense} += $mapped_reads->{sense};
    $rpkm_values{mapped_reads_antisense} += $mapped_reads->{antisense};
  }
  
  $rpkm_values{rpkm_sense} = $self->_calculate_rpkm($rpkm_values{mapped_reads_sense});
  $rpkm_values{rpkm_antisense} = $self->_calculate_rpkm($rpkm_values{mapped_reads_antisense});
  
  return \%rpkm_values;
}

sub _calculate_rpkm
{
  my ($self, $mapped_reads) = @_;
  #my $rpkm  = $mapped_reads / ( ($self->feature->exon_length/1000) * ($self->total_mapped_reads/1000000) );
  # same equation, rewritten
  my $rpkm  = ($mapped_reads / $self->feature->exon_length) * (1000000000/$self->total_mapped_reads);
  
  
  return $rpkm;
}


1;