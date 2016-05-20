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
      if params[:s].present?
        params[:s] = params[:s].map { |k, v| [ "search_#{k}".to_sym, v ] }.to_h
        params.require(:s).permit(permit_fields)
      else
        {}
      end
    end

    def permit_fields
      @model.permitted_fields
    end

    def set_item
      @item = @model.new pre_params.merge(fix_params)
    end
end
