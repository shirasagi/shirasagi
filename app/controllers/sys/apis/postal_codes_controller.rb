class Sys::Apis::PostalCodesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Sys::PostalCode

  def index
    @multi = params[:single].blank?
    @items = @model.search(params[:s]).order_by(prefecture_code: 1, code: 1, id: 1).page(params[:page]).per(50)
  end
end
