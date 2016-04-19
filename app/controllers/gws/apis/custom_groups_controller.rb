class Gws::Apis::CustomGroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::CustomGroup

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      target_to(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
