class Cms::Apis::Preview::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  before_action :set_item, only: [:publish]
  before_action :set_cur_node, only: [:publish]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_cur_node
    @cur_node ||= (@item.parent || nil)
  end

  public

  def publish
    raise "403" if !@item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)

    if @item.try(:release_date).present?
      @item.state = "ready"
    else
      @item.state = "public"
    end
    result = @item.save

    if !result
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    location = nil
    if @item.try(:branch?) && @item.state == "public"
      location = cms_preview_path(path: @item.master.url[1..-1])
      @item.delete
    end

    render json: { reload: location.blank?, location: location }, status: :ok
  end
end
