class Gws::StaffRecord::PublicDutiesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::PublicYearlyFilter

  model Gws::StaffRecord::User

  before_action :prepare_edit_charge, only: [:edit_charge, :update_charge]

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.divide_duties"), action: :index]
  end

  def get_charge_params
    params.require(:item).permit(:charge_address, :charge_tel).merge(fix_params).to_h
  end

  def prepare_edit_charge
    set_item
    raise "403" unless @item.editable_charge?(@cur_user)
  end

  public

  def index
    @limit = params.dig(:s, :limit).presence || @cur_site.divide_duties_limit
    users = @cur_year.yearly_users

    @s = OpenStruct.new params[:s]
    unless @s[:section_name]
      user = users.where(code: @cur_user.organization_uid).first
      @s[:section_name] = user.try(:section_name).presence || @cur_group.trailing_name
    end

    @items = users.show_divide_duties.
      readable(@cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).
      per(@limit)
  end

  def show
    raise "403" unless @item.readable?(@cur_user)

    @items = @cur_year.yearly_users.show_divide_duties.
      readable(@cur_user, site: @cur_site).
      where(section_name: @item.section_name).
      where(charge_name: @item.charge_name).
      all
  end

  def edit_charge
    if @item.is_a?(Cms::Addon::EditLock)
      return redirect_to(action: :lock) unless @item.acquire_lock
    end
  end

  def update_charge
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    result = @cur_year.yearly_users.show_divide_duties.
      readable(@cur_user, site: @cur_site).
      where(section_name: @item.section_name).
      where(charge_name: @item.charge_name).
      update_all(get_charge_params)

    render_update true, render: { file: :edit_charge }
  end
end
