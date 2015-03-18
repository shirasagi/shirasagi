class Opendata::CrawlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  #model Opendata::Dataset
  model Opendata::UrlResource

  navi_view "opendata/main/navi"

  public
  def index
    @datasets = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)
    @items = []
    package_list = []
    #@model_crawl = Opendata::UrlResource

    @datasets.each do |dataset|
      package_list << dataset[:name]
      dataset.url_resources.each do |urlresource|
        item = {id: dataset._id,
                urlresourceid: urlresource._id,
                resourcename: dataset.name,
                name: urlresource.name,
                crawl_state:   urlresource.crawl_state,
                filename: urlresource.filename,
                original_updated: urlresource.original_updated,
                original_url: urlresource.original_url}
        @items << item
      end
    end
  end
end

