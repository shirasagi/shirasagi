# coding: utf-8
module Cms::PartFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  private
    def append_view_paths
      append_view_path ["app/views/cms/parts", "app/views/ss/crud"]
    end

    def render_route
      @item.route = params[:route] if params[:route].present?
      @fix_params = fix_params

      cell = "#{@item.route.sub('/', '/parts/')}/edit"
      resp = render_cell cell, params[:action]

      if resp.is_a?(String)
        @resp = resp
      else
        @item = resp
      end
    end

    def redirect_url
      nil
    end

  public
    def show
      render_route
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      render_route
    end

    def create
      @item = @model.new get_params
      render_route
      render_create @resp.blank?, location: redirect_url
    end

    def edit
      render_route
    end

    def update
      @item.attributes = get_params
      render_route
      render_update @resp.blank?, location: redirect_url
    end

    def delete
      render_route
    end

    def destroy
      render_route
      render_destroy @resp.blank?, location: redirect_url
    end
end
