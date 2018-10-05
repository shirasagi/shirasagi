class Gws::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Group

  navi_view "gws/main/conf_navi"

  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/group"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    super
    raise "403" unless Gws::Group.site(@cur_site).include?(@item)
  end

  def reload_nginx
    SS::Nginx::Config.new.write.reload_server
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      allow(:read, @cur_user, site: @cur_site)

    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
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

  def download
    csv = @model.unscoped.site(@cur_site).order_by(_id: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_groups_#{Time.zone.now.to_i}.csv"
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
