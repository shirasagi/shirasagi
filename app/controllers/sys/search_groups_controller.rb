class Sys::SearchGroupsController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Sys::Group

  public
    def index
      @items = @model.
        search(params[:s]).
        order_by(_id: -1)
    end
end
