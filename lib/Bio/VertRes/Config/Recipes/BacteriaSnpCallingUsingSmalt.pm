package Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSmalt;
# ABSTRACT: Standard snp calling pipeline for bacteria

=head1 SYNOPSIS

Standard snp calling pipeline for bacteria. Register study, QC, map with smalt, snp call
   use Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSmalt;
   
   my $obj = Bio::VertRes::Config::Recipes::BacteriaSnpCallingUsingSmalt->new( 
     database => 'abc', 
     limits => {project => ['Study ABC']}, 
     reference => 'ABC', 
     reference_lookup_file => '/path/to/refs.index',
     additional_mapper_params => '',
     mapper_index_params => ''
     );
   $obj->create;
   
=cut

use Moose;
use Bio::VertRes::Config::Pipelines::QC;
use Bio::VertRes::Config::Pipelines::SmaltMapping;
use Bio::VertRes::Config::Pipelines::SnpCalling;
use Bio::VertRes::Config::RegisterStudy;
extends 'Bio::VertRes::Config::Recipes::Common';
with 'Bio::VertRes::Config::Recipes::Roles::RegisterStudy';
with 'Bio::VertRes::Config::Recipes::Roles::Reference';
with 'Bio::VertRes::Config::Recipes::Roles::CreateGlobal';
with 'Bio::VertRes::Config::Recipes::Roles::BacteriaSnpCalling';

has 'additional_mapper_params' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'mapper_index_params'      => ( is => 'ro', isa => 'Maybe[Str]' );

override '_pipeline_configs' => sub {
    my ($self) = @_;
    my @pipeline_configs;
    
    $self->add_qc_config(\@pipeline_configs);
    
    push(
        @pipeline_configs,
        Bio::VertRes::Config::Pipelines::SmaltMapping->new(
            database                       => $self->database,
            config_base                    => $self->config_base,
            overwrite_existing_config_file => $self->overwrite_existing_config_file,
            limits                         => $self->limits,
            reference                      => $self->reference,
            reference_lookup_file          => $self->reference_lookup_file,
            additional_mapper_params       => $self->additional_mapper_params,
            mapper_index_params            => $self->mapper_index_params
        )
    );
    
    # Insert BAM Improvment here
    
    $self->add_bacteria_snp_calling_config(\@pipeline_configs);
    
    return \@pipeline_configs;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
