class Opendata::Csv2rdfSetting
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User

  SIMILARITY_THRESHOLD = 0.6.freeze

  attr_accessor :cur_dataset, :cur_resource

  seqid :id
  belongs_to :dataset, class_name: "Opendata::Dataset"
  # belongs_to :resource, class_name: "Opendata::Resource"
  field :resource_id, type: Integer
  field :header_rows, type: Integer
  field :header_labels, type: Array
  field :class_id, type: Integer
  field :column_types, type: Array

  permit_params :header_rows, :class_id

  scope :resource, ->(resource) { where(resource_id: resource.id) }

  before_validation :set_dataset_id, if: ->{ @cur_dataset }
  before_validation :set_resource_id, if: ->{ @cur_resource }
  before_validation :update_header_labels
  before_validation :update_column_types

  validates :dataset_id, presence: true
  validates :resource_id, presence: true

  def resource
    dataset.resources.find(resource_id)
  end

  def header_cols
    return header_labels.length if header_labels.present?
    nil
  end

  def rdf_class
    Rdf::Class.site(site).where(_id: class_id).first
  end

  def set_dataset_id
    self.dataset_id ||= @cur_dataset.id
  end

  def set_resource_id
    self.resource_id ||= @cur_resource.id
  end

  def update_header_labels
    return if header_rows.blank?
    if header_labels.blank? || resource_id_changed?
      self.header_labels = fetch_header_labels
    end
  end

  def fetch_header_labels
    tsv = resource.parse_tsv
    labels = []
    0.upto(header_rows - 1) do |i|
      labels << tsv[i]
    end
    labels.transpose.map.with_index(1) do |column_labels, index|
      column_labels = column_labels.map(&:strip).select(&:present?)
      if column_labels.join.blank?
        # set default column name
        ["分類#{index}"]
      else
        column_labels
      end
    end
  end

  def update_column_types
    return if header_labels.blank?
    return if class_id.blank?

    if column_types.blank? || header_labels_changed? || class_id_changed?
      self.column_types = search_column_types
    end
  end

  def search_column_types
    Opendata::ColumnTypesSearcher::Searcher.call(self, SIMILARITY_THRESHOLD)
  end
end
