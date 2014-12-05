class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View

  before_action :accept_cors_request

  public

    def index
      render
    end

    def package_list

      @items = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)

      package_list = []
      @items.each do |item|
        package_list << item[:name]
      end

      res = {
        help: "Package List",
        success: true,
        result: package_list,
      }

      render json: res
    end

end
