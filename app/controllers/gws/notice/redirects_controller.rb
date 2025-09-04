class Gws::Notice::RedirectsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Post

  def show
    set_item

    raise "404" if @item.deleted.present?

    if @item.public? && @item.readable?(@cur_user, site: @cur_site)
      redirect_to gws_notice_readable_path
    else
      redirect_to gws_notice_editable_path
    end
  end
end
