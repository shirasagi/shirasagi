class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.group"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  def set_item
    @item = @model.unscoped.site(@cur_site).find params[:id]
    @item.attributes = fix_params
    raise "403" unless @model.unscoped.site(@cur_site).include?(@item)
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence if @search_params

    @items = @model.unscoped.site(@cur_site).
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site)

    if @search_params
      @items = @items.search(@search_params).
        order_by(name: 1, order: 1, id: 1)
    else
      @items = @items.tree_sort
    end
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def role_edit
    set_item
    return "404" if @item.users.blank?
    render :role_edit
  end

  def role_update
    set_item
    role_ids = params[:item][:cms_role_ids].select(&:present?).map(&:to_i)

    @item.users.each do |user|
      set_ids = user.cms_role_ids - Cms::Role.site(@cur_site).map(&:id) + role_ids
      user.set(cms_role_ids: set_ids)
    end
    render_update true
  end

  def download
    csv = @model.unscoped.site(@cur_site).order_by(_id: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "cms_groups_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
