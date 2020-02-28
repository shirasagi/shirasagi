class Opendata::Resource
  include SS::Document
  include Opendata::Resource::Model
  include Opendata::Resource::Previewable
  include Opendata::Addon::RdfStore
  include Opendata::Addon::CmsRef::AttachmentFile
  include Opendata::Addon::Harvest::Resource
  include Opendata::Addon::ZipDataset

  attr_accessor :workflow, :status

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  field :order, type: Integer, default: 0

  permit_params :name, :text, :format, :license_id, :source_url, :order

  validates :in_file, presence: true, if: ->{ file_id.blank? && source_url.blank? }
  validates :format, presence: true
  #validates :source_url, format: /\A#{URI::regexp(%w(https http))}$\z/, if: ->{ source_url.present? }

  before_validation :set_source_url, if: ->{ source_url.present? }
  before_validation :set_filename, if: ->{ in_file.present? }
  before_validation :escape_source_url, if: ->{ source_url.present? }
  before_validation :validate_in_file, if: ->{ in_file.present? }
  before_validation :validate_in_tsv, if: ->{ in_tsv.present? }
  before_validation :set_format

  after_save :save_dataset

  def context_path
    "/resource"
  end

  def create_download_history(remote_addr, user_agent, downloaded)
    Opendata::ResourceDownloadHistory.create_history(
      site: dataset.site,
      dataset: dataset,
      resource: self,
      remote_addr: remote_addr,
      user_agent: user_agent,
      downloaded: downloaded,
      downloaded_by: "single"
    )
  end

  def create_bulk_download_history(remote_addr, user_agent, downloaded)
    Opendata::ResourceDownloadHistory.create_history(
      site: dataset.site,
      dataset: dataset,
      resource: self,
      remote_addr: remote_addr,
      user_agent: user_agent,
      downloaded: downloaded,
      downloaded_by: "bulk"
    )
  end

  def create_dataset_download_history(remote_addr, user_agent, downloaded)
    Opendata::ResourceDownloadHistory.create_history(
      site: dataset.site,
      dataset: dataset,
      resource: self,
      remote_addr: remote_addr,
      user_agent: user_agent,
      downloaded: downloaded,
      downloaded_by: "dataset"
    )
  end

  def create_preview_history(remote_addr, user_agent, previewed)
    Opendata::ResourcePreviewHistory.create_history(
      site: dataset.site,
      dataset: dataset,
      resource: self,
      remote_addr: remote_addr,
      user_agent: user_agent,
      previewed: previewed
    )
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  private

  def set_filename
    self.filename = in_file.original_filename
    self.format = filename.sub(/.*\./, "").upcase if format.blank?
  end

  def escape_source_url
    return if source_url.ascii_only?
    self.source_url = ::Addressable::URI.escape(source_url)
  end

  def validate_in_file
    #if %(CSV TSV).index(format)
    #  errors.add :file_id, :invalid if parse_tsv(in_file).blank?
    #end
  end

  def validate_in_tsv
    errors.add :tsv_id, :invalid if parse_tsv(in_tsv).blank?
  end

  def set_format
    return if format.blank?

    self.format = format.upcase
    self.rm_tsv = "1" if %(CSV TSV).index(format)
  end

  def save_dataset
    self.workflow ||= {}
    dataset.cur_site = dataset.site
    dataset.apply_status(status, workflow) if status.present?
    dataset.released ||= Time.zone.now
    dataset.save(validate: false)
  end

  def set_source_url
    if in_file
      self.source_url = nil
    else
      self.filename = nil
      self.file.destroy if file
    end
  end
end
