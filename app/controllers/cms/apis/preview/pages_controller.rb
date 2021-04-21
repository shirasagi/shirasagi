class Cms::Apis::Preview::PagesController < ApplicationController
  include Cms::ApiFilter
  include Cms::LockFilter

  model Cms::Page
  append_view_path "app/views/cms/crud"

  before_action :set_item, only: [:publish]
  before_action :set_cur_node, only: [:publish]
  before_action :check_lockable_item, only: [:lock, :unlock]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_cur_node
    @cur_node ||= (@item.parent || nil)
  end

  def set_item
    super
    return @item if @item.blank? || @item.class != Cms::Page
    @item = @item.becomes_with_route rescue @item
  end

  def check_lockable_item
    set_item

    if !@item.respond_to?(:acquire_lock)
      # respond ok if @item doesn't support lock or unlock operation
      render json: [], status: :ok
      return
    end
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
      @item.skip_history_trash = true if @item.respond_to?(:skip_history_trash)
      @item.delete
    end

    render json: { reload: location.blank?, location: location }, status: :ok
  end
end
