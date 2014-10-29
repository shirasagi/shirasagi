class Facility::MainController < ApplicationController
  include Cms::BaseFilter

  public
    def index
      if @cur_node.route =~ /\/category/
        redirect_to facility_categories_path
        return
      elsif @cur_node.route =~ /\/location/
        redirect_to facility_locations_path
        return
      elsif @cur_node.route =~ /\/service/
        redirect_to facility_services_path
        return
      else
        redirect_to facility_pages_path
        return
      end
    end
end
