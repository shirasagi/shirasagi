class Gws::PersonalAddress::AddressesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Webmail::Address

  before_action :set_address_group
  before_action :set_group_navi, only: [:index]

  navi_view "gws/personal_address/main/navi"

  private

  def set_crumbs
    set_address_group
    @crumbs << [@cur_site.menu_personal_address_label || t("modules.gws/personal_address"), gws_personal_address_addresses_path]
    @crumbs << [@address_group.name, action: :index] if @address_group
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def set_address_group
    return if params[:group].blank?
    @address_group ||= Webmail::AddressGroup.user(@cur_user).find(params[:group])
  end

  def set_group_navi
    @group_navi = Webmail::AddressGroup.user(@cur_user)
  end

  public

  def index
    s_params = params[:s] || {}
    s_params[:address_group_id] = @address_group.id if @address_group.present?

    @items = @model.user(@cur_user).
      search(s_params).
      page(params[:page]).per(50)
  end

  def download
    s_params = params[:s] || {}
    s_params[:address_group_id] = @address_group.id if @address_group.present?

    items = @model.user(@cur_user).
      search(s_params)

    @item = @model.new(fix_params)
    send_data @item.export_csv(items), filename: "personal_addresses_#{Time.zone.now.to_i}.csv"
  end

  def download_template
    send_data @model.new.export_csv([]), filename: "personal_addresses_template.csv"
  end

  def import
    return if request.get?

    @item = @model.new(get_params)
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
