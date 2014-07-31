# coding: utf-8
class History::Sys::LogsController < ApplicationController
  include Sys::BaseFilter

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

      require "csv"
      csv = CSV.generate do |data|
        data << %w[Date User Target Action URL]
        @model.where(cond).sort(created: 1).each do |item|
          line = []
          line << item.created.strftime("%Y-%m-%d %H:%m")
          line << item.user_label
          line << item.target_label
          line << item.action
          line << item.url
          data << line
        end
      end

      send_data csv.encode("SJIS"), filename: "history_sys_logs_#{Time.now.to_i}.csv"
    end

    def delete
      @item = @model.new
    end

    def destroy
      from = @model.term_to_date params[:item][:save_term]
      raise "500" if from == false

      cond = { site_id: nil }
      cond[:created] = { "$lt" => from }

      num  = @model.delete_all(cond)

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
