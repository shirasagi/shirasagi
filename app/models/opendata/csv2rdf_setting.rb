class Opendata::Csv2rdfSetting
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User

  SIMILARITY_THRESHOLD = 0.6.freeze
  MAX_ROWS = 19.freeze

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
    return 0 unless header_labels.present?
    header_labels.length
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
    actual_rows = tsv.size
    max_rows = header_rows < actual_rows ? header_rows :  actual_rows

    labels = []
    0.upto(max_rows - 1) do |i|
      labels << tsv[i]
    end

    labels.transpose.map.with_index(1) do |column_labels, index|
      column_labels = column_labels.select(&:present?).map(&:strip)
      if column_labels.join.blank?
        # set default column name
        ["#{I18n.t("opendata.labels.group")}#{index}"]
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

  def search_column_types(opts = {})
    opts = { threshold: SIMILARITY_THRESHOLD, max_rows: MAX_ROWS }.merge(opts)
    Opendata::ColumnTypesSearcher::Searcher.call(self, opts)
  end

  def validate_header_size
    if header_rows.blank?
      errors.add :header_rows, :blank
      return
    end

    if header_rows <= 0
      errors.add :header_rows, :greater_than, count: 0
      return
    end

    tsv = resource.parse_tsv
    if header_rows > tsv.size
      errors.add :header_rows, :less_than, count: tsv.size
      return
    end
  end

  def validate_rdf_class
    validate_header_size
    errors.add :class_id, :blank if class_id.blank?
  end

  def validate_column_types
    # nothing to do
    validate_rdf_class
  end
end
