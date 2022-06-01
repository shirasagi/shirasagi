class Sys::Apis::UsersController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model SS::User

  def index
    @items = @model.search(params[:s])
  end
end
