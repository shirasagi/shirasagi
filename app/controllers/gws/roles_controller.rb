class Gws::RolesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Role

  prepend_view_path "app/views/ss/roles"
  navi_view "gws/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/role"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(name: 1).
      page(params[:page]).per(50)
  end

  def download
    csv = @model.unscoped.site(@cur_site).order_by(_id: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_roles_#{Time.zone.now.to_i}.csv"
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
