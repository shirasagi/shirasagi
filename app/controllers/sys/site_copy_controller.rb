class Sys::SiteCopyController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::SiteCopyTask
  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"sys.site_copy", sys_site_copy_path]
    end

    def set_item
      @item ||= Sys::SiteCopyTask.order_by(id: 1).first_or_initialize
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)

      set_item
      @item.clear_params

      respond_to do |format|
        format.html { render }
        format.json { render json: @item.to_json }
      end
    end

    def confirm
      set_item
      @item.clear_params
      @item.attributes = get_params
      if @item.valid?
        respond_to do |format|
          format.html { render }
          format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
        end
      else
        respond_to do |format|
          format.html { render action: :index }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
        end
      end
    end

    def run
      set_item
      @item.attributes = get_params
      @item.state = 'ready'
      @item.started = nil
      @item.closed = nil
      @item.logs = []
      if @item.save
        Sys::SiteCopyJob.perform_later

        respond_to do |format|
          format.html { redirect_to({ action: :index }, { notice: I18n.t('sys.site_copy/started_job') }) }
          format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
        end
      else
        respond_to do |format|
          format.html { render action: :index }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
        end
      end
    end
end
