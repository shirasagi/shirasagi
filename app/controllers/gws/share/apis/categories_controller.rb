class Gws::Share::Apis::CategoriesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Share::Category

  before_action :set_category

  private
    def set_category
      @groups = @model.site(@cur_site).reduce([]) do |ret, g|
        indent = '-' * g.depth
        ret << [ "#{indent} #{g.trailing_name}".html_safe, g.id ]
      end.to_a

      @group = params[:s] ? params[:s][:group] : nil
    end

    def parent_name
      return // unless @group
      parent = @model.where(id: @group).first
      return // unless parent
      /^#{parent.name}\//
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
