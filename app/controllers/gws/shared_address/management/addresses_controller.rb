class Gws::SharedAddress::Management::AddressesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::SharedAddress::Address

  before_action :set_address_group
  before_action :set_group_navi, only: [:index]

  navi_view "gws/shared_address/main/navi"

  private

  def set_crumbs
    set_address_group
    @crumbs << [@cur_site.menu_shared_address_label || t("modules.gws/shared_address"), gws_shared_address_addresses_path]
    @crumbs << [t("mongoid.models.gws/shared_address/address"), gws_shared_address_management_addresses_path]
    @crumbs << [@address_group.name, action: :index] if @address_group
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_address_group
    return if params[:group].blank?
    @address_group ||= Gws::SharedAddress::Group.site(@cur_site).find(params[:group])
  end

  def set_group_navi
    @group_navi = Gws::SharedAddress::Group.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    s_params = params[:s] || {}
    s_params[:address_group_id] = @address_group.id if @address_group.present?

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(s_params).
      page(params[:page]).per(50)
  end

  def download
    s_params = params[:s] || {}
    s_params[:address_group_id] = @address_group.id if @address_group.present?

    items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(s_params)

    @item = @model.new(fix_params)
    send_data @item.export_csv(items), filename: "shared_addresses_#{Time.zone.now.to_i}.csv"
  end

  def download_template
    send_data @model.new.export_csv([]), filename: "shared_addresses_template.csv"
  end

  def import
    return if request.get?

    @item = @model.new(get_params)
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
