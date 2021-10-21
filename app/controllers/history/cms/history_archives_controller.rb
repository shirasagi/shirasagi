class History::Cms::HistoryArchivesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::HistoryArchiveFile

  navi_view "history/cms/logs/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), action: :index]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:read, @cur_user)

    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
