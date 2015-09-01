class Cms::SearchContents::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents

  model Cms::Page

  append_view_path "app/views/cms/search_contents/pages"
  navi_view "cms/search_contents/navi"

  private
    def set_params
      @name     = params[:s][:name]
      @filename = params[:s][:filename]
      @state    = params[:s][:state]
      @released = params[:s][:released]
      @updated  = params[:s][:updated]

      @category_ids = params[:s][:category_ids].select(&:present?).map(&:to_i)
      @categories = Category::Node::Base.in(_id: @category_ids).entries
      @categories = @category_ids.map { |id| @categories.find { |item| item.id == id } }

      @group_ids = params[:s][:group_ids].select(&:present?).map(&:to_i)
      @groups = SS::Group.in(_id: @group_ids).entries
      @groups = @group_ids.map { |id| @groups.find { |item| item.id == id } }
    end

  public
    def index
      @items = []
      @categories = []
      @groups = []
      return unless params[:s]

      set_params
      filename   = @filename.present? ? { filename: /#{Regexp.escape(@filename)}/i } : {}
      categories = @category_ids.present? ? { category_ids: @category_ids } : {}
      groups     = @group_ids.present? ? { group_ids: @group_ids } : {}
      state      = @state ? { state: @state } : {}

      released = []
      if @released
        start = @released[:start]
        close = @released[:close]
        released << { :released.gte => start } if start.present?
        released << { :released.lte => close } if close.present?
      end

      updated = []
      if @updated
        start = @updated[:start]
        close = @updated[:close]
        updated << { :updated.gte => start } if start.present?
        updated << { :updated.lte => close } if close.present?
      end

      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        search(params[:s]).
        where(filename).
        in(categories).
        in(groups).
        where(state).
        and(released).
        and(updated).
        order_by(filename: 1).
        page(params[:page]).per(25)
    end
end
