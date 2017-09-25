class Gws::Facility::CustomFieldsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::CustomField

  navi_view 'gws/facility/settings/navi'

  private

  def set_facility
    @cur_facility ||= Gws::Facility::Item.site(@cur_site).find_by(params[:item_id])
  end

  def set_crumbs
    set_facility
    @crumbs << [t('mongoid.models.gws/facility/group_setting'), gws_facility_items_path]
    @crumbs << [t('mongoid.models.gws/facility/group_setting/item'), gws_facility_items_path]
    @crumbs << [@cur_facility.name, gws_facility_item_path(id: @cur_facility)]
  end

  def fix_params
    set_facility
    { cur_user: @cur_user, cur_site: @cur_site, cur_facility: @cur_facility }
  end

  def set_item
    set_facility
    @item = @cur_facility.custom_fields.find(params[:id])
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    set_facility
    raise '403' unless @cur_facility.allowed?(:read, @cur_user, site: @cur_site)
    @items = @cur_facility.custom_fields.
      page(params[:page]).per(50)
  end

  def new
    set_facility
    raise '403' unless @cur_facility.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    set_facility
    raise '403' unless @cur_facility.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new get_params
    render_create @item.save
  end

  def show
    raise '403' unless @cur_facility.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise '403' unless @cur_facility.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @cur_facility.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.save
  end

  def delete
    raise '403' unless @cur_facility.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @cur_facility.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    raise '403' unless @cur_facility.allowed?(:delete, @cur_user, site: @cur_site)

    entries = @items.entries
    @items = []

    entries.each do |item|
      next if item.disable
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
