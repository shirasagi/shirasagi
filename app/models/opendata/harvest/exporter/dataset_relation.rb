class Opendata::Harvest::Exporter
  class DatasetRelation
    include SS::Document

    # shirasagi attributes
    belongs_to :exporter, class_name: 'Opendata::Harvest::Exporter'
    belongs_to :dataset, class_name: 'Opendata::Dataset'
    embeds_many :rel_resources, class_name: 'Opendata::Harvest::Exporter::ResourceRelation'
    field :uuid, type: String

    # relations
    field :rel_id, type: String

    validates :uuid, presence: true
    validates :rel_id, presence: true

    class << self
      def exported(exporter, dataset)
        where(exporter_id: exporter.id, dataset_id: dataset.id).first
      end
    end
  end
end
