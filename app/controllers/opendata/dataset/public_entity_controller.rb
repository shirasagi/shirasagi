class Opendata::Dataset::PublicEntityController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::PublicEntityDataset

  navi_view "opendata/main/navi"
  menu_view nil

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
  end

  def download
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @items = Opendata::Dataset.site(@cur_site).and_public.order_by(id: -1)
    send_enum @items.public_entity_enum_csv(@cur_node), type: 'text/csv; charset=Shift_JIS',
      filename: "datasets_list_#{Time.zone.now.to_i}.csv"
  end
end
