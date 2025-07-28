class Opendata::Harvest::Exporter
  class ResourceRelation
    include SS::Document

    # shirasagi attributes
    embedded_in :rel_dataset, class_name: 'Opendata::Harvest::Exporter::DatasetRelation', inverse_of: :rel_resources
    field :uuid, type: String
    field :revision_id, type: String

    # relations
    field :rel_id, type: String

    validates :uuid, presence: true
    validates :revision_id, presence: true
    validates :rel_id, presence: true
  end
end
