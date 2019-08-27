class Gws::Report::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Report::File

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).without_deleted.and_public
    @items = @items.accessible(@cur_user, site: @cur_site)
    @items = @items.search(params[:s]).page(params[:page]).per(50)
  end
end
