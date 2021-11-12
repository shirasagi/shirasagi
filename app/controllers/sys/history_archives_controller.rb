class Sys::HistoryArchivesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::HistoryArchiveFile

  navi_view "history/sys/logs/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), action: :index]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:read, @cur_user)

    @items = @model.where(site_id: nil).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
