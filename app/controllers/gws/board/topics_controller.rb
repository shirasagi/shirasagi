class Gws::Board::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Board::Topic

  before_action :set_category

  private
    def set_crumbs
      set_category
      if @category.present?
        @crumbs << [:"modules.gws/board", gws_board_topics_path]
        @crumbs << [@category.name, action: :index]
      else
        @crumbs << [:"modules.gws/board", action: :index]
      end
    end

    def set_category
      @categories = Gws::Board::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
      if category_id = params[:category].presence
        @category ||= Gws::Board::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
      end
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def pre_params
      p = super
      if @category.present?
        p[:category_ids] = [ @category.id ]
      end
      p
    end

  public
    def index
      @items = @model.site(@cur_site).topic

      if params[:s] && params[:s][:state] == "closed"
        @items = @items.and_closed.allow(:read, @cur_user, site: @cur_site)
      else
        @items = @items.and_public.readable(@cur_user, @cur_site)
      end

      if @category.present?
        params[:s] ||= {}
        params[:s][:site] = @cur_site
        params[:s][:category] = @category.name
      end

      @items = @items.search(params[:s]).
        order(descendants_updated: -1).
        page(params[:page]).per(50)
    end

    def show
      raise '403' unless @item.readable?(@cur_user)
      render file: "show_#{@item.mode}"
    end
end
