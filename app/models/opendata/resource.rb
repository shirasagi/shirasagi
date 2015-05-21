class Opendata::Resource
  include SS::Document
  include Opendata::Resource::Model
  include SS::Relation::File
  include Opendata::Addon::RdfStore

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource

  permit_params :name, :text, :format, :license_id

  validates :in_file, presence: true, if: ->{ file_id.blank? }
  validates :format, presence: true

  before_validation :set_filename, if: ->{ in_file.present? }
  before_validation :validate_in_file, if: ->{ in_file.present? }
  before_validation :validate_in_tsv, if: ->{ in_tsv.present? }
  before_validation :set_format

  after_save -> { dataset.save(validate: false) }
  after_destroy -> { dataset.save(validate: false) }

  public
    def context_path
      "/resource"
    end

  private
    def set_filename
      self.filename = in_file.original_filename
      self.format = filename.sub(/.*\./, "").upcase if format.blank?
    end

    def validate_in_file
      if %(CSV TSV).index(format)
        errors.add :file_id, :invalid if parse_tsv(in_file).blank?
      end
    end

    def validate_in_tsv
      errors.add :tsv_id, :invalid if parse_tsv(in_tsv).blank?
    end

    def set_format
      self.format = format.upcase if format.present?
      self.rm_tsv = "1" if %(CSV TSV).index(format)
    end
end
