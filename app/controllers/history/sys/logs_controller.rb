class History::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include History::LogFilter::View

  model History::Log

  before_action :filter_permission

  private
    def set_crumbs
      @crumbs << [:"history.log", action: :index]
    end

    def filter_permission
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)
    end

  public
    def index
      @items = @model.
        where(site_id: nil).
        order_by(created: -1).
        page(params[:page]).per(50)
    end

    def download
      @item = @model.new
      return if request.get?

      from = @model.term_to_date params[:item][:save_term]
      raise "500" if from == false

      cond = { }
      cond[:created] = { "$gte" => from } if from

      @items = @model.where(cond).sort(created: 1)
      send_csv @items
    end

    def destroy
      from = @model.term_to_date params[:item][:save_term]
      raise "500" if from == false

      cond = { site_id: nil }
      cond[:created] = { "$lt" => from }

      num  = @model.delete_all(cond)

      coll = @model.new.collection
      coll.session.command({ compact: coll.name })

      render_destroy num
    end
end
