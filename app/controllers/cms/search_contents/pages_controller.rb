class Cms::SearchContents::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents

  model Cms::PageSearch

  append_view_path "app/views/cms/search_contents/pages"
  navi_view "cms/search_contents/navi"
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

  public
    def index
      if params[:save]
        redirect_to new_cms_page_search_path(item: item_attributes)
        return
      end
    end
end
