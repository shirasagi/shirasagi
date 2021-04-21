class Cms::UsersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::User

  navi_view "cms/main/conf_navi"
  menu_view "cms/users/menu"
  before_action :set_selected_items, only: [:destroy_all, :lock_all, :unlock_all]

  private

  def set_crumbs
    @crumbs << [t("cms.user"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def set_item
    @item = @model.unscoped.site(@cur_site, state: 'all').find params[:id]
    @item.attributes = fix_params
    raise "403" unless @model.unscoped.site(@cur_site, state: 'all').include?(@item)
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @selected_items = @items = @model.unscoped.in(id: ids)
    raise "400" unless @items.present?
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @model.unscoped.site(@cur_site, state: 'all').
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def update
    other_group_ids = Cms::Group.nin(id: Cms::Group.site(@cur_site).pluck(:id)).in(id: @item.group_ids).pluck(:id)
    other_role_ids = Cms::Role.nin(id: Cms::Role.site(@cur_site).pluck(:id)).in(id: @item.cms_role_ids).pluck(:id)

    @item.attributes = get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    @item.update

    @item.add_to_set(group_ids: other_group_ids)
    @item.add_to_set(cms_role_ids: other_role_ids)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disabled? ? @item.destroy : @item.disable
  end

  def destroy_all
    disable_all
  end

  def download
    csv = @model.unscoped.site(@cur_site, state: 'all').allow(:read, @cur_user, site: @cur_site, node: @cur_node).
      order_by(_id: 1).to_csv(site: @cur_site)
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "cms_users_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end

  def lock_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        item.attributes = fix_params
        next if item.lock
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.lock_user_all'))
  end

  def unlock_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        item.attributes = fix_params
        next if item.unlock
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.unlock_user_all'))
  end
end
