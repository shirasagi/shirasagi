class Cms::Apis::Preview::RedirectorController < ApplicationController
  include Cms::ApiFilter

  def new_page
    if @cur_node.present?
      location = url_for(controller: "/" + @cur_node.route.pluralize, action: :new) rescue nil
      location ||= new_node_page_path(cid: @cur_node)
    else
      location = new_cms_page_path
    end

    respond_to do |format|
      format.html { redirect_to location }
      format.json { render json: { location: location }.to_json }
    end
  end
end
