class Gws::Apis::FacilitiesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Facility::Item

  before_action :set_category

  private
    def set_category
      @groups = Gws::Facility::CategoryTraverser.build(@cur_site)
      @groups = @groups.flatten

      @group = params[:s] ? params[:s][:group].presence : nil
      if @group
        @group = Gws::Facility::Category.site(@cur_site).find(@group) rescue nil
      end
    end

    def category_ids
      return if @group.blank?
      ids = Gws::Facility::Category.site(@cur_site).where(name: /^#{Regexp.escape(@group.name)}\//).pluck(:id)
      ids << @group.id
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        readable(@cur_user, @cur_site, exclude_role: true).
        reservable(@cur_user).
        active.
        search(params[:s])
      @items = @items.in(category_id: category_ids) if @group.present?
      @items = @items.page(params[:page]).per(50)
    end
end
