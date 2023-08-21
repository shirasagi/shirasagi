class Cms::PageSearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::PageSearch
  navi_view "cms/main/conf_navi"

  private

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def pre_params
    if params[:item].present?
      params.require(:item).permit(permit_fields)
    else
      {}
    end
  end

  public

  def destroy_all_pages
    @model = Cms::Page
    set_selected_items

    raise "400" if @selected_items.blank?

    if params[:destroy_all]
      render_confirmed_all(destroy_items, location: { action: :show })
      return
    end

    respond_to do |format|
      format.html { render "destroy_all" }
      format.json { head json: errors }
    end
  end

  def search
    set_item
  end
end
