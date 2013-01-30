package Bio::VertRes::Config::Pipelines::Mapping;

# ABSTRACT: The base class for the mapping pipeline.

=head1 SYNOPSIS

The base class for the mapping pipeline. It wont produce useable output on its own, you need to call a sub classed mapper for that.
   use Bio::VertRes::Config::Pipelines::Mapping;

   my $pipeline = Bio::VertRes::Config::Pipelines::Mapping->new(
     database => 'abc',
     reference => 'Staphylococcus_aureus_subsp_aureus_ABC_v1',
     limits => {
       project => ['ABC study'],
       species => ['EFG']
     },
     slx_mapper => 'bwa',
     slx_mapper_exe => '/path/to/mapper/mapper.exe'

     );
   $pipeline->to_hash();

=cut

use Moose;
use Bio::VertRes::Config::Pipelines::Common;
use Bio::VertRes::Config::References;
use Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter;
use Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix;
extends 'Bio::VertRes::Config::Pipelines::Common';
with 'Bio::VertRes::Config::Pipelines::Roles::MetaDataFilter';
with 'Bio::VertRes::Config::Pipelines::Roles::MultiplePrefix';

has 'pipeline_short_name'   => ( is => 'ro', isa => 'Str', default  => 'mapping' );
has 'module'                => ( is => 'ro', isa => 'Str', default  => 'VertRes::Pipelines::Mapping' );
has 'reference'             => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference_lookup_file' => ( is => 'ro', isa => 'Str', default => '/lustre/scratch108/pathogen/pathpipe/refs/refs.index' );
has 'toplevel_action'       => ( is => 'ro', isa => 'Str', default => '__VRTrack_Mapping__' );

has 'slx_mapper'            => ( is => 'ro', isa => 'Str', required => 1 );
has 'slx_mapper_exe'        => ( is => 'ro', isa => 'Str', required => 1 );

has '_reference_fasta'      => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_build__reference_fasta');
has '_mark_duplicates'      => ( is => 'ro', isa => 'Int', default => 1 );
has '_do_cleanup'           => ( is => 'ro', isa => 'Int', default => 1 );
has '_do_recalibration'     => ( is => 'ro', isa => 'Int', default => 0 );
has '_exit_on_errors'       => ( is => 'ro', isa => 'Int', default => 0 );
has '_get_genome_coverage'  => ( is => 'ro', isa => 'Int', default => 1 );
has '_add_index'            => ( is => 'ro', isa => 'Int', default => 1 );
has '_ignore_mapped_status' => ( is => 'ro', isa => 'Int', default => 1 );

sub _build__reference_fasta {
    my ($self) = @_;
    Bio::VertRes::Config::References->new( reference_lookup_file => $self->reference_lookup_file )
      ->get_reference_location_on_disk( $self->reference );
}

override 'log_file_name' => sub {
    my ($self) = @_;
    my $output_filename = "";
    for my $limit_type (qw(project sample library)) {
        if ( defined $self->limits->{$limit_type} ) {
            my $list_of_limit_values = $self->limits->{$limit_type};
            for my $limit_value ( @{$list_of_limit_values} ) {
                $limit_value =~ s/^\s+|\s+$//g;
                $output_filename = $output_filename . '_' . $limit_value;
            }
        }
    }
    
    $output_filename .= join('_',($self->reference, $self->slx_mapper));

    $output_filename =~ s!\W+!_!g;
    $output_filename =~ s/_$//g;

    if ( length($output_filename) > 80 ) {
        $output_filename = substr( $output_filename, 0, 76 ) . '_' . int(rand(999));
    }
    return join( '.', ( $output_filename, 'log' ) );
};

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();

    $output_hash->{vrtrack_processed_flags} = { import => 1, qc => 1, stored => 1 };
    $output_hash->{limits}                     = $self->limits;
    $output_hash->{data}{mark_duplicates}      = $self->_mark_duplicates;
    $output_hash->{data}{reference}            = $self->_reference_fasta;
    $output_hash->{data}{assembly_name}        = $self->reference;
    $output_hash->{data}{do_cleanup}           = $self->_do_cleanup;
    $output_hash->{data}{do_recalibration}     = $self->_do_recalibration;
    $output_hash->{data}{exit_on_errors}       = $self->_exit_on_errors;
    $output_hash->{data}{get_genome_coverage}  = $self->_get_genome_coverage;
    $output_hash->{data}{add_index}            = $self->_add_index;
    $output_hash->{data}{ignore_mapped_status} = $self->_ignore_mapped_status;
    $output_hash->{data}{slx_mapper}           = $self->slx_mapper;
    $output_hash->{data}{slx_mapper_exe}       = $self->slx_mapper_exe;

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

