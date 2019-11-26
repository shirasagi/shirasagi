class Opendata::ResourceDownloadHistory
  include SS::Document
  include SS::Reference::Site

  index({ site_id: 1, downloaded: -1 })

  field :dataset_id, type: Integer
  field :dataset_name, type: String

  field :dataset_areas, type: Array, default: []
  field :dataset_categories, type: Array, default: []
  field :dataset_estat_categories, type: Array, default: []

  field :resource_id, type: Integer
  field :resource_name, type: String
  field :resource_filename, type: String
  field :resource_source_url, type: String

  field :full_url, type: String
  field :downloaded, type: DateTime
  field :downloaded_by, type: String
  field :remote_addr, type: String
  field :user_agent, type: String

  class << self
    def create_history(site:, dataset:, resource:, remote_addr:, user_agent:, downloaded:, downloaded_by:)
      self.create(
        cur_site: site,
        dataset_id: dataset.id,
        dataset_name: dataset.name,
        dataset_areas: dataset.areas.and_public.order_by(order: 1).pluck(:name),
        dataset_categories: dataset.categories.and_public.order_by(order: 1).pluck(:name),
        dataset_estat_categories: dataset.estat_categories.and_public.order_by(order: 1).pluck(:name),
        resource_id: resource.id,
        resource_name: resource.name,
        resource_filename: resource.filename,
        resource_source_url: resource.source_url,
        full_url: dataset.full_url,
        downloaded: (downloaded || Time.zone.now),
        downloaded_by: downloaded_by.presence || "single",
        remote_addr: remote_addr,
        user_agent: user_agent
      )
    end

    def search(params)
      all.search_keyword(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in params[:keyword], :dataset_name, :resource_name
    end
  end
end

class Opendata::ResourceDownloadHistory::ArchiveFile
  include SS::Model::File
  include SS::Reference::Site

  default_scope ->{ where(model: "opendata/resource_download_history/archive_file") }
end

class Opendata::ResourceDownloadHistory::HistoryCsv
  include ActiveModel::Model

  attr_accessor :cur_site, :items

  CSV_HEADERS = %i[
    downloaded downloaded_by dataset_id dataset_name dataset_areas dataset_categories dataset_estat_categories
    resource_id resource_name resource_filename resource_source_url full_url remote_addr user_agent
  ].freeze

  class << self
    def enum_csv(cur_site, items)
      new(cur_site: cur_site, items: items).enum_csv
    end
  end

  def csv_headers
    CSV_HEADERS.map { |k| Opendata::ResourceDownloadHistory.t(k) }
  end

  def enum_csv(opts = {})
    Enumerator.new do |y|
      y << encode_sjis(csv_headers.to_csv)
      items.each do |item|
        y << encode_sjis(to_csv(item))
      end
    end
  end

  def to_csv(item)
    terms = []
    CSV_HEADERS.each do |k|
      if k == :downloaded
        terms << I18n.l(item.downloaded)
      else
        terms << item.send(k)
      end
    end
    terms.to_csv
  end

  private

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
