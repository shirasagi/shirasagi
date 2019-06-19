class Webmail::HistoryArchivesController < ApplicationController
  include Webmail::BaseFilter
  include Sys::CrudFilter

  model Webmail::History::ArchiveFile

  # navi_view 'gws/histories/navi'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/history"), action: :index]
  end

  public

  def index
    raise '403' unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.all.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
