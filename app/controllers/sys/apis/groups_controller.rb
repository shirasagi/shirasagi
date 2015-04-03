class Sys::Apis::GroupsController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Sys::Group

  public
    def index
      @items = @model.
        search(params[:s])
    end
end
