class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::MypageFilter

  before_action :accept_cors_request
  skip_filter :logged_in?

  public

    def index
      render
    end

    def package_list

      #@items = Opendata::Dataset.site(@cur_site).member(@cur_member).order_by(updated: -1)
      @items = Opendata::Dataset.site(@cur_site).order_by(filename: 1)

      render :json => @items.to_json
    end

end
