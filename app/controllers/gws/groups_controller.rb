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
    if SS.config.ss.updates_and_reloads_nginx_conf
      SS::Nginx::Config.new.write.reload_server
    end
  end

  public

  def index
    # 修正したら app/controllers/cms/groups_controller.rb など、同じような個所が何か所かあるので同じように修正すべし
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    state = params.dig(:s, :state).to_s.presence

    if @search_params || state == "disabled"
      criteria = @model.unscoped.site(@cur_site)
      criteria = criteria.state(state)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(@search_params)
      criteria = criteria.reorder(name: 1, order: 1, id: 1)
      @items = criteria.page(params[:page]).per(SS.max_items_per_page)
      @component = nil
    else
      @items = nil
      @component = Gws::GroupTreeComponent.new(cur_site: @cur_site, cur_user: @cur_user, cur_group: @cur_group, state: state)
    end
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def download_all
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @model = SS::DownloadParam

    if request.get? || request.head?
      @item = SS::DownloadParam.new
      render
      return
    end

    @item = SS::DownloadParam.new params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    csv = Gws::Group.unscoped.site(@cur_site).order_by(_id: 1).to_csv
    case @item.encoding
    when "Shift_JIS"
      csv = csv.encode("SJIS", invalid: :replace, undef: :replace)
    when "UTF-8"
      csv = SS::Csv::UTF8_BOM + csv
    end

    send_data csv, filename: "gws_groups_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    @item = @model.new get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
