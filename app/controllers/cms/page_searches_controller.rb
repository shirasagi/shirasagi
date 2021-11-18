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

    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, location: { action: :show })
  end

  def search
    set_item
  end
end
