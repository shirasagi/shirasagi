class History::Cms::HistoryArchivesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::HistoryArchiveFile

  navi_view "history/cms/logs/navi"

  private

  def set_crumbs
    @crumbs << [t("history.log"), history_cms_logs_path]
    @crumbs << [t("mongoid.models.gws/history_archive_file"), action: :index]
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
