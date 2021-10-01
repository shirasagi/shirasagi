class Cms::SearchContents::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents
  include Cms::CrudFilter

  model Cms::PageSearch

  append_view_path "app/views/cms/search_contents/pages"
  navi_view "cms/search_contents/navi"
  menu_view nil
  before_action :set_item

  private

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def pre_params
    params[:item] ? params.require(:item).permit(permit_fields) : {}
  end

  def permit_fields
    @model.permitted_fields
  end

  def get_params
    if params[:item].present?
      params.require(:item).permit(permit_fields).merge(fix_params)
    else
      fix_params
    end
  end

  def set_item
    @item = @model.new get_params
  end

  def item_attributes
    attr = @item.attributes.except(:site_id, :_id, :id, :order)
    @item.fields.each do |n, f|
      v = @item.send(n)
      next unless v.present?

      if f.type == DateTime
        attr[n.to_s] = v.strftime("%Y/%m/%d %H:%M")
      elsif f.type == Date
        attr[n.to_s] = v.strftime("%Y/%m/%d")
      end
    end
    attr
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @items = Cms::Page.in(id: ids)
    raise "400" unless @items.present?
  end

  public

  def index
    if params[:save]
      redirect_to new_cms_page_search_path(item: item_attributes)
      return
    end

    if params[:download]
      filename = @model.to_s.tableize.tr("/", "_")
      filename = "#{filename}_#{Time.zone.now.to_i}.csv"
      send_enum @item.enum_csv, type: 'text/csv; charset=Shift_JIS', filename: filename
    end
  end

  def destroy_all_pages
    set_selected_items

    entries = @items.entries
    @items = []

    entries.each do |item|
      item = item.becomes_with_route rescue item
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, location: cms_page_search_contents_path)
  end
end
