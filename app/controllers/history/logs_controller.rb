# coding: utf-8
class History::LogsController < ApplicationController
  include Cms::BaseFilter

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

    def delete
      #
    end

    def destroy
      num = @model.delete_all site_id: @cur_site.id

      coll = @model.new.collection
      coll.session.command({ compact: coll.name })

      location = { action: :index }

      if num
        respond_to do |format|
          format.html { redirect_to location, notice: t(:deleted) }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render file: :delete }
          format.json { render json: :error, status: :unprocessable_entity }
        end
      end
    end
end
