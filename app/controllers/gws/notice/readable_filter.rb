module Gws::Notice::ReadableFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_folders
    before_action :set_folder
    before_action :set_categories
    before_action :set_category
    before_action :set_search_params
    before_action :set_items
  end

  private

  def set_folders
    @folders ||= Gws::Notice::Folder.for_post_reader(@cur_site, @cur_user)
  end

  def set_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @folder = @folders.find(params[:folder_id])
  end

  def set_categories
    @categories ||= Gws::Notice::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    @s[:site] = @cur_site
    @s[:user] = @cur_user
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_reader(@cur_site, @cur_user).pluck(:id)
    end
    @s[:category_id] = @category.id if @category.present?
    @s[:browsed_state] = @cur_site.notice_browsed_state if @s[:browsed_state].nil?
    @s[:severity] = @cur_site.notice_severity if @s[:severity].nil?
  end

  def set_items
    @items = @model.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).
      without_deleted
  end
end
