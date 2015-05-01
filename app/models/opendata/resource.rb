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

    def set_format
      self.format = format.upcase if format.present?

      if tsv_present? && tsv
        self.rm_tsv = "1"
      end
    end
end
