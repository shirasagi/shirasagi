class Cms::SearchContents::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents
  include SS::FileFilter

  model SS::File

  navi_view "cms/search_contents/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.file"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    file_ids = []
    Cms::Page.each do |page|
      page.file_ids.each { |file_id| file_ids.push file_id }
    end
    file_ids = file_ids.uniq.compact.sort
    @items = @model.where(site_id: @cur_site).
      search(params[:s]).
      in(id: file_ids).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
