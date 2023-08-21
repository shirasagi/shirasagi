class Cms::Apis::Pages::ChildrenController < ApplicationController
  include Cms::ApiFilter
  include Cms::Apis::PageFilter

  model Cms::Page

  prepend_view_path "app/views/cms/apis/pages"

  private

  def set_select_items
    if @selected_node
      super
    else
      @items = @model.none
    end
  end

  public

  def index
    @items = @items.
      order_by(_id: -1).
      page(params[:page]).per(50)

    if params[:layout] == "iframe"
      render layout: "ss/ajax_in_iframe"
    end
  end
end
