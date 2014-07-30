# coding: utf-8
class Cms::SearchCategoriesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Category::Node::Base

  public
    def index
    end

    def search
      @query = params[:q]
      @query = @query.blank? ? {} : @query.split(/[\s　]+/).map { |q| { name: /#{q}/ } }

      @items = @model.site(@cur_site).
        and(@query).
        order_by(_id: -1)#.page(params[:page]).per(20)

      render layout: !request.xhr?
    end

end
