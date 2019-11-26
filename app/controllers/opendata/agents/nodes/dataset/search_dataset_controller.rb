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
    downloaded = Time.zone.now

    item = Opendata::Dataset.site(@cur_site).and_public.find_by(id: params[:id])
    item.resources.each do |resource|
      if !preview_path?
        resource.dataset.inc downloaded: 1
        resource.create_dataset_download_history(remote_addr, request.user_agent, downloaded)
      end
    end

    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    send_file item.zip_path, type: 'application/zip', filename: "#{item.name}_#{Time.zone.now.to_i}.zip",
      disposition: :attachment, x_sendfile: true
  end

  def bulk_download
    ids = params[:ids].to_a.map(&:to_i)
    filename = "opendata-datasets-#{Time.zone.now.to_i}"

    @items = Opendata::Dataset.site(@cur_site).and_public.in(id: ids).select { |item| item.zip_exists? }

    bulk_download_size = @items.map(&:zip_size).sum
    if bulk_download_size > SS.config.opendata.bulk_download_max_filesize
      head 422
      return
    end

    begin
      t = Tempfile.new(filename)
      downloaded = Time.zone.now

      Zip::File.open(t.path, Zip::File::CREATE) do |zip|
        @items.each do |item|
          zip.add("#{item.name}-#{item.id}.zip".encode('cp932', invalid: :replace, undef: :replace), item.zip_path)
          item.resources.each do |resource|
            if !preview_path?
              resource.dataset.inc downloaded: 1
              resource.create_bulk_download_history(remote_addr, request.user_agent, downloaded)
            end
          end
        end
      end

      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

      send_data ::Fs.read(t.path), type: 'application/zip', filename: "#{t("opendata.dataset")}_#{Time.zone.now.to_i}.zip",
        disposition: :attachment, x_sendfile: true
    ensure
      t.delete
      t.close
    end
  end
end
