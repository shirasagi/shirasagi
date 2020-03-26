class Opendata::Resource
  include SS::Document
  include Opendata::Resource::Model
  include Opendata::Resource::Previewable
  include Opendata::Addon::RdfStore
  include Opendata::Addon::CmsRef::AttachmentFile
  include Opendata::Addon::Harvest::Resource
  include Opendata::Addon::ZipDataset

  DOWNLOAD_CACHE_LIFETIME = 10.minutes

  attr_accessor :workflow, :status

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :resource
  field :order, type: Integer, default: 0
  field :downloaded_count_cache, type: Hash

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

  class << self
    def context_path
      "/resource"
    end
  end

  delegate :context_path, to: :class

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

  def downloaded_count
    # 日付が変わってすぐに履歴がレポート化されるわけではない。
    # このようなことから、日付が変わってすぐにページが書き出されると、ダウンロード数が減ってしまう可能性がある。
    # これを防止するために、苦肉の策ではあるが、直前のダウンロード数をデータベースに保存しておいてい、
    # ダウンロード数が増加した場合にのみ、ダウンロード数を更新するようにする。
    # 追加で、ダウンロード数をデータベースへ保存するに際して、ついでにキャッシュ化し、負荷の低減を図るものとする。
    now = Time.zone.at(Time.zone.now.to_i) # beginning_of_second

    if downloaded_count_cache.present?
      lifetime = downloaded_count_cache["created"].in_time_zone + DOWNLOAD_CACHE_LIFETIME
      return downloaded_count_cache["value"] if lifetime >= now
    end

    report_criteria = Opendata::ResourceDownloadReport.site(dataset.site)
    report_criteria = report_criteria.where(dataset_id: dataset.id, resource_filename: filename)
    counts = report_criteria.pluck(*Opendata::Resource::ReportModel::DAY_COUNT_FIELDS).flatten.compact
    count = counts.sum

    history_criteria = Opendata::ResourceDownloadHistory.site(dataset.site)
    history_criteria = history_criteria.gte(downloaded: now.beginning_of_day)
    history_criteria = history_criteria.where(resource_id: id)
    count += history_criteria.count

    # downloaded count never decreases previous count
    return downloaded_count_cache["value"] if downloaded_count_cache.present? && count < downloaded_count_cache["value"]

    self.set(downloaded_count_cache: { "value" => count, "created" => now }) if persisted?
    count
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
