class Opendata::Agents::Nodes::Dataset::SearchDatasetController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  private

  def pages
    @model = Opendata::Dataset

    focus = params.permit(s: [@model.search_params])[:s].presence || {}
    focus = focus.merge(site: @cur_site)

    sort = Opendata::Dataset.sort_hash(params.dig(:s, :sort) || params.permit(:sort)[:sort])

    @model.site(@cur_site).and_public.
      search(focus).
      order_by(sort)
  end

  def st_categories
    @cur_node.parent_dataset_node.st_categories.presence || @cur_node.parent_dataset_node.default_st_categories
  end

  def st_estat_categories
    @cur_node.parent_dataset_node.st_estat_categories.presence || @cur_node.parent_dataset_node.default_st_estat_categories
  end

  public

  def index
    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @cur_estat_categories = st_estat_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @items = pages.page(params[:page]).per(@cur_node.limit || 20)
  end

  def index_tags
    @cur_node.layout = nil
    @tags = pages.aggregate_array :tags
    render "opendata/agents/nodes/dataset/search_dataset/tags", layout: "opendata/dataset_aggregation"
  end

  def search
    @model = Opendata::Dataset
    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @cur_estat_categories = st_estat_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
  end

  def rss
    @items = pages.limit(100)
    render_rss @cur_node, @items
  end

  def dataset_download
    @model = Opendata::Dataset
    item = @model.site(@cur_site).and_public.find_by(id: params[:id])
    filepath = "#{item.zip_path}/opendata-datasets-#{item.id}.zip"
    item.resources.each do |resource|
      if Mongoid::Config.clients[:default_post].blank?
        resource.dataset.inc downloaded: 1
        resource.create_dataset_download_history
      end
    end

    send_file filepath, type: 'application/zip', filename: "#{item.name}_#{Time.zone.now.to_i}.zip",
      disposition: :attachment, x_sendfile: true
  end

  def bulk_download
    @model = Opendata::Dataset
    ids = params[:ids].to_a.map(&:to_i)
    @items = @model.site(@cur_site).and_public.in(id: ids)
    filename = "opendata-datasets-#{Time.zone.now.to_i}"
    t = Tempfile.new(filename)
    Zip::File.open(t.path, Zip::File::CREATE) do |zip|
      @items.each do |item|
        path = "#{item.zip_path}/opendata-datasets-#{item.id}.zip"
        next unless item.zip_exists?
        zip.add("#{item.name}-#{item.id}.zip".encode('cp932', invalid: :replace, undef: :replace), path)
        item.resources.each do |resource|
          if Mongoid::Config.clients[:default_post].blank?
            resource.dataset.inc downloaded: 1
            resource.create_bulk_download_history
          end
        end
      end
    end
    send_data ::Fs.read(t.path), type: 'application/zip', filename: "#{t("opendata.dataset")}_#{Time.zone.now.to_i}.zip",
      disposition: :attachment, x_sendfile: true
    t.delete
    t.close
  end
end
