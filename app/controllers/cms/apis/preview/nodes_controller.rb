class Cms::Apis::Preview::NodesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def publish
    raise "403" if !@cur_node.allowed?(:edit, @cur_user, site: @cur_site)

    if @cur_node.try(:release_date).present?
      @cur_node.state = "ready"
    else
      @cur_node.state = "public"
    end
    result = @cur_node.save

    if !result
      render json: @cur_node.errors.full_messages, status: :unprocessable_entity
      return
    end

    render json: { reload: true }, status: :ok
  end

  def new_page
    if @cur_node.present?
      route = @cur_node.view_route.presence || @cur_node.route
      location = url_for(controller: "/" + route.pluralize, action: :new) rescue nil
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
