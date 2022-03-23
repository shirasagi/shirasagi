class Cms::SearchContents::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents
  include SS::FileFilter

  model SS::File

  navi_view "cms/search_contents/navi"

  if Rails.env.development?
    before_action { ::Rails.application.eager_load! }
  end

  private

  def set_crumbs
    @crumbs << [t("cms.file"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    page = params[:page].try { |page| page.to_s.numeric? ? page.to_s.to_i - 1 : nil } || 0
    service = Cms::FileSearchService.new(cur_site: @cur_site, cur_user: @cur_user, s: params[:s], page: page, limit: 50)
    @items = service.call
  end
end
