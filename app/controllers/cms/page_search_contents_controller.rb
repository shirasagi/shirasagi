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
    set_selected_items

    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, location: { action: :show })
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
    @items = Cms::Page.in(id: ids)
    raise "400" unless @items.present?
  end
end
