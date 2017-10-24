class Gws::Report::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Report::File

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      readable(@cur_user, @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
