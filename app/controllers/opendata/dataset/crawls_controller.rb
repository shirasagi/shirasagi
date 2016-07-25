class Opendata::Dataset::CrawlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::UrlResource

  navi_view "opendata/main/navi"

  public
  def index
    @datasets = Opendata::Dataset.site(@cur_site).and_public.order_by(name: 1)
    @items = []
    package_list = []
    @datasets.each do |dataset|
      package_list << dataset[:name]

      dataset.url_resources.
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50).each do |urlresource|

        unless params[:s].blank?
          if params[:s][:search_updated]=="1" && params[:s][:search_deleted]=="1"
            next unless urlresource.crawl_state == "updated" || urlresource.crawl_state == "deleted"
          elsif  params[:s][:search_updated]=="1"
            next unless urlresource.crawl_state == "updated"
          elsif  params[:s][:search_deleted]=="1"
            next unless urlresource.crawl_state == "deleted"
          end
        end

        item = {id: dataset._id,
            urlresourceid: urlresource._id,
            resourcename: dataset.name,
            name: urlresource.name,
            crawl_state:   urlresource.crawl_state,
            filename: urlresource.filename,
            original_updated: urlresource.original_updated,
            original_url: urlresource.original_url,
            crawl_update:   urlresource.crawl_update}
        @items << item
      end
    end
  end
end

