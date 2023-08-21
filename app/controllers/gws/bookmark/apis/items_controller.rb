class Gws::Bookmark::Apis::ItemsController < ApplicationController
  include Gws::ApiFilter
  include Gws::CrudFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Item

  before_action :set_item

  private

  def get_params
    params.require(:bookmark).permit(permit_fields).merge(fix_params)
  rescue
    raise "400"
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    url = params.dig(:bookmark, :url).to_s
    model = params.dig(:bookmark, :bookmark_model).to_s

    @bookmark = @cur_user.find_bookmark(@cur_site, url, bookmark_model: model)
    @bookmark_folders = @folders.to_a.sort_by(&:order)

    @bookmark_default_name = params[:default_name].to_s
    @bookmark_url = url
    @bookmark_model = model
  end

  def set_selected_items
  end

  public

  def update
    if !@model.allowed?(:edit, @cur_user, site: @cur_site)
      raise "403"
    end

    @bookmark ||= @model.new
    @bookmark.attributes = get_params
    @bookmark.name = @bookmark_default_name if @bookmark.name.blank?
    @bookmark.folder ||= @cur_user.bookmark_root_folder(@cur_site)

    @new_bookmark = @bookmark.new_record?
    @bookmark.save

    render :update, layout: false
  end

  def destroy
    if !@model.allowed?(:delete, @cur_user, site: @cur_site)
      raise "403"
    end

    @bookmark.destroy if @bookmark
    render :create, layout: false
  end
end
