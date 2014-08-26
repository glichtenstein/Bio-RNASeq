package gffTestHelper;
use Moose::Role;
use Test::Most;
use File::Slurp;
use File::Compare;
use Data::Dumper;


sub _run_rna_seq {

    my ( $sam_file, $annotation_file, $results_library, $protocol ) = @_;

    open OLDOUT, '>&STDOUT';
    open OLDERR, '>&STDERR';

    {

        local *STDOUT;
        open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
        local *STDERR;
        open STDERR, '>/dev/null' or warn "Can't open /dev/null: $!";

        my $bam_file = $sam_file;
        $bam_file =~ s/sam$/bam/;
        unlink($bam_file) if ( -e $bam_file );

        `samtools view -bS $sam_file 2>/dev/null > $bam_file`;

        my $file_temp_obj =
          File::Temp->newdir( DIR => File::Spec->curdir(), CLEANUP => 1 );

        my $output_base_filename = $file_temp_obj->dirname() . '/test_';

        my $intergenic_regions = 1;
        my %filters = ( mapping_quality => 1 );

        my $test_name = $results_library->[0]->[3];

        ok(
            my $expression_results = Bio::RNASeq->new(
                sequence_filename    => $bam_file,
                annotation_filename  => $annotation_file,
                filters              => \%filters,
                protocol             => $protocol,
                output_base_filename => $output_base_filename,
                intergenic_regions   => $intergenic_regions,
            ),
            $test_name . ' expression_results object creation'
        );

        ok( $expression_results->output_spreadsheet(),
            $test_name . ' expression results spreadsheet creation' );

        ok( -e $output_base_filename . '.corrected.bam',
            $test_name . ' corrected bam' );
        ok( -e $output_base_filename . '.corrected.bam.bai',
            $test_name . ' corrected bai' );

        ok(
            -e $output_base_filename
              . '.corrected.bam.intergenic.DUMMY_CHADO_CHR.tab.gz',
            'intergenic gz'
        );

        ok(
            -e $output_base_filename . '.expression.csv',
            $test_name . ' expression results'
        );

        my $filename = $output_base_filename . '.expression.csv';

        for my $set_of_expected_results (@$results_library) {
            parseExpressionResultsFile( $filename, $set_of_expected_results );
        }

        close STDOUT;
        close STDERR;
        unlink($bam_file);
    }

    ## Restore stdout.
    open STDOUT, '>&OLDOUT' or die "Can't restore stdout: $!";
    open STDERR, '>&OLDERR' or die "Can't restore stderr: $!";

    # Avoid leaks by closing the independent copies.
    close OLDOUT or die "Can't close OLDOUT: $!";
    close OLDERR or die "Can't close OLDERR: $!";

}

sub run_rna_seq {
  
  my ( $sam_file, $annotation_file, $results_library ) = @_;
  return _run_rna_seq( $sam_file, $annotation_file, $results_library, 'StandardProtocol' );

}

sub run_rna_seq_strand_specific {

  my ( $sam_file, $annotation_file, $results_library ) = @_;
  return _run_rna_seq( $sam_file, $annotation_file, $results_library, 'StrandSpecificProtocol' );

}


sub parseExpressionResultsFile {

    my ( $filename, $set_of_expected_results ) = @_;


    my $csv = Text::CSV->new();
    open( my $fh, "<:encoding(utf8)", $filename ) or die("$filename: $!");

    my $headers = $csv->getline($fh);

    my $column_index = 0;
    for my $header (@$headers) {

        if ( $header eq $set_of_expected_results->[1] ) {
            last;
        }
        $column_index++;
    }

    while ( my $row = $csv->getline($fh) ) {
        unless ( $row->[1] eq $set_of_expected_results->[0] ) {
            next;
        }
        is( $row->[$column_index], $set_of_expected_results->[2],
            "match $set_of_expected_results->[1] - $set_of_expected_results->[0]" );
        last;
    }
    $csv->eof or $csv->error_diag();
    close $fh;

}

1;
