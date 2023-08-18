class Cms::Apis::Translate::LangsController < ApplicationController
  include Cms::ApiFilter

  model ::Translate::Lang

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
