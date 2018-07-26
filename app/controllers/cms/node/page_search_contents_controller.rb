class Cms::Node::PageSearchContentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  navi_view "cms/main/navi"
  menu_view nil
  model Cms::PageSearch

  before_action -> { @list_head_search = true }, only: :show

  def download
    set_item
    csv = @item.to_csv(@cur_site, @cur_user).encode("SJIS", invalid: :replace, undef: :replace)
    send_data csv, filename: "page_search_#{Time.zone.now.to_i}.csv"
  end

  private

  def set_crumbs
    set_item
    @crumbs << [ @item.name, action: :show ]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end
end
