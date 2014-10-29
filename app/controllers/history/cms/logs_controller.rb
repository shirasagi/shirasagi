class History::Cms::LogsController < ApplicationController
  include Cms::BaseFilter
  include History::LogFilter::View

  model History::Log

  navi_view "cms/main/navi"

  before_action :filter_permission
  skip_filter :put_log

  private
    def set_crumbs
      @crumbs << [:"history.log", action: :index]
    end

    def filter_permission
      raise "403" unless Cms::User.allowed?(:edit, @cur_user, site: @cur_site)
    end

  public
    def index
      @items = @model.site(@cur_site).
        order_by(created: -1).
        page(params[:page]).per(50)
    end

    def download
      @item = @model.new
      return if request.get?

      from = @model.term_to_date params[:item][:save_term]
      raise "500" if from == false

      cond = { site_id: @cur_site.id }
      cond[:created] = { "$gte" => from } if from

      @items = @model.where(cond).sort(created: 1)
      send_csv @items
    end

    def destroy
      from = @model.term_to_date params[:item][:save_term]
      raise "500" if from == false

      cond = { site_id: @cur_site.id }
      cond[:created] = { "$lt" => from }

      num  = @model.delete_all(cond)

      coll = @model.new.collection
      coll.session.command({ compact: coll.name })

      render_destroy num
    end
end
