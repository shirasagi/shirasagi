class Cms::Apis::Preview::InplaceEdit::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  layout "ss/ajax_in_iframe"

  before_action :set_inplace_mode

  private

  def set_inplace_mode
    @inplace_mode = true
  end

  public

  def edit
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" if !@item.allowed?(:approve, @cur_user, site: @cur_site)
    end

    super
  end

  def update
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" if !@item.allowed?(:approve, @cur_user, site: @cur_site)
    end

    super
  end
end
