class Gws::HistoryArchivesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::HistoryArchiveFile

  navi_view 'gws/histories/navi'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), gws_histories_path]
    @crumbs << [t("mongoid.models.gws/history_archive_file"), action: :index]
  end

  public

  def index
    raise '403' unless Gws::HistoryArchiveFile.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
