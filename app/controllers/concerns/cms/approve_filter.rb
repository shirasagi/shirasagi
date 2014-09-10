# coding: utf-8
module Cms::ApproveFilter
  extend ActiveSupport::Concern

  public
    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      raise "403" unless @item.allowed?(:release, @cur_user) if @item.state == "public"
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      raise "403" unless @item.allowed?(:release, @cur_user) if @item.state == "public"
      render_update @item.update
    end
end
