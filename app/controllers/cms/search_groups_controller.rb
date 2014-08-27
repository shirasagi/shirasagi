# coding: utf-8
class Cms::SearchGroupsController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Cms::Group

  public
    def index
    end

    def search
      @query = params[:q]
      @query = @query.blank? ? {} : @query.split(/[\s　]+/).uniq.compact.map { |q| { name: /\Q#{q}\E/ } }

      @items = @model.site(@cur_site).
        and(@query).
        order_by(_id: -1)

      render layout: !request.xhr?
    end

end
