class Job::Sys::TasksController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model SS::Task
  navi_view "job/sys/main/navi"

  private
    def set_crumbs
      @crumbs << [:"job.task", action: :index]
    end

    def set_item
      @item = @model.find(params[:id])
      raise "404" unless @item
    end

  public
    def index
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
      @items = @model.order_by(started: -1, id: -1).page(params[:page]).per(50)
    end

    def show
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
      render
    end

    def delete
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
      render
    end

    def destroy
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
      render_destroy @item.destroy
    end

    def destroy_all
      entries = @items.entries
      @items = []

      entries.each do |item|
        next if item.destroy
        @items << item
      end
      render_destroy_all(entries.size != @items.size)
    end

    def reset_state
      set_item
      @item.state = 'stop'
      if @item.save
        respond_to do |format|
          format.html { redirect_to({ action: :index }, { notice: I18n.t('job.notice.reseted_state') }) }
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
