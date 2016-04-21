class Gws::Share::Apis::CategoriesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Share::Category

  before_action :set_category

  private
    def set_category
      @groups = Gws::Share::CategoryTraverser.build(@cur_site, @cur_user)
      @groups = @groups.flatten

      @group = params[:s] ? params[:s][:group].presence : nil
      @group = @model.where(id: @group).first if @group.present?
    end

    def parent_name
      return // unless @group
      /^#{@group.name}\//
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        search(params[:s]).
        where(name: parent_name).
        page(params[:page]).per(50)
    end
end
