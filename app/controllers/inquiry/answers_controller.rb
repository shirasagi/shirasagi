class Inquiry::AnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Inquiry::Answer

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      render
    end

    def delete
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render_destroy @item.destroy
    end
end
