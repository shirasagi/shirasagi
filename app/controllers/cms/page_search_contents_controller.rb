class Cms::PageSearchContentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/main/navi"
  menu_view nil
  model Cms::PageSearch

  before_action -> { @list_head_search = true }, only: :show

  def download
    set_item
    csv = @item.to_csv(@cur_site, @cur_user).encode("SJIS", invalid: :replace, undef: :replace)
    send_data csv, filename: "page_search_#{Time.zone.now.to_i}.csv"
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    if params[:destroy_all]
      render_confirmed_all(destroy_items, location: { action: :show })
      return
    end

    respond_to do |format|
      format.html { render "destroy_all" }
      format.json { head json: errors }
    end
  end

  private

  def set_crumbs
    set_item
    @crumbs << [ @item.name, action: :show ]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @selected_items = Cms::Page.in(id: ids).site(@cur_site)
    raise "400" unless @selected_items.present?
  end
end
