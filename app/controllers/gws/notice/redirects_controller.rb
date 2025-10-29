class Gws::Notice::RedirectsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Post

  def show
    set_item

    raise "404" if @item.deleted.present?

    unless @model.public_states.include?(@item.state)
      redirect_to gws_notice_editable_path
      return
    end

    unless @item.readable?(@cur_user, site: @cur_site)
      redirect_to gws_notice_editable_path
      return
    end

    if @item.public?
      redirect_to gws_notice_readable_path
      return
    end

    if @cur_site.notice_back_number_menu_visible?
      redirect_to gws_notice_back_number_path
      return
    end

    # @item はバックナンバー。しかし、バックナンバーを表示する権限がない
    redirect_to gws_notice_editable_path
  end
end
