class Sys::Apis::PrefectureCodesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Sys::PrefectureCode

  def index
    @multi = params[:single].blank?
    @items = @model.search(params[:s]).order_by(code: 1, id: 1).page(params[:page]).per(50)
  end
end
