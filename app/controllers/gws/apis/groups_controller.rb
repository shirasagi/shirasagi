class Gws::Apis::GroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Group

  def index
    @multi = params[:single].blank?

    @s = params[:s].presence

    @items = @model.site(@cur_site).active
    if @s.present?
      @items = @items.search(params[:s]).
        reorder(name: 1).
        page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end
end
