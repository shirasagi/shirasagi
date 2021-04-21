class Opendata::Dataset::DatasetsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Workflow::PageFilter

  model Opendata::Dataset

  append_view_path "app/views/cms/pages"
  navi_view "opendata/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    @items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end

  def check_for_update
    set_item

    render layout: "ss/ajax"
  end

  def copy
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if request.get?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}" unless @item.cloned_name?
      return
    end

    @copy = @item.new_clone(get_params)
    render_update @copy.save, location: { action: :index }, render: { file: :copy }
  end
end
