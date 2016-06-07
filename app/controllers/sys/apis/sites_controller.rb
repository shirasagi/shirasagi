class Sys::Apis::SitesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Sys::Site

  def index
    @items = @model.search(params[:s])
  end
end
