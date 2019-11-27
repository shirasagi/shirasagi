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
        downloaded_by: (downloaded_by.presence || "single"),
        remote_addr: remote_addr,
        user_agent: user_agent
      )
    end

    def search(params)
      all.search_ymd(params).search_keyword(params)
    end

    def search_ymd(params)
      return all if params.blank? || params[:ymd].blank?

      ymd = params[:ymd]
      ymd = Time.zone.parse(ymd) if ymd.is_a?(String)
      ymd = ymd.in_time_zone
      ymd = ymd.beginning_of_day

      all.gte(downloaded: ymd).lt(downloaded: ymd + 1.day)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in params[:keyword], :dataset_name, :resource_name
    end
  end

  def downloaded_by_options
    %w(single dataset bulk).map do |v|
      [ I18n.t("opendata.downloaded_by_options.#{v}"), v ]
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
    downloaded downloaded_by full_url dataset_id dataset_name dataset_areas dataset_categories dataset_estat_categories
    resource_id resource_name resource_filename resource_source_url remote_addr user_agent
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
      elsif k == :downloaded_by
        if item.is_a?(Opendata::ResourceDatasetDownloadHistory)
          terms << I18n.t("opendata.downloaded_by_options.dataset")
        elsif item.is_a?(Opendata::ResourceBulkDownloadHistory)
          terms << I18n.t("opendata.downloaded_by_options.bulk")
        else
          terms << (item.label(:downloaded_by).presence || I18n.t("opendata.downloaded_by_options.single"))
        end
      elsif %i[dataset_areas dataset_categories dataset_estat_categories].include?(k)
        terms << item.send(k).join("\n")
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
