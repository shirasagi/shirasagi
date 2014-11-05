class Sys::SearchGroupsController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model SS::Group

  public
    def index
      search if params[:q]
    end

    def search
      @query = params[:q]
      @query = @query.blank? ? { name: /.+/ } : @query.split(/[\s　]+/).map { |q| { name: /#{q}/ } }

      @items = @model.
        and(@query).
        order_by(_id: -1).
        page(params[:page]).per(20)

      render :search, layout: !request.xhr?
    end

end
