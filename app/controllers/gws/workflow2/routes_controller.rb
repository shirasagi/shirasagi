class Gws::Workflow2::RoutesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::Route

  navi_view "gws/workflow2/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t('modules.gws/workflow2'), gws_workflow2_setting_path]
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    super
    raise "403" unless @model.site(@cur_site).include?(@item)
  end

  def set_default_readable_setting
    @item.readable_setting_range = "private"
    @item.readable_group_ids = []
    @item.readable_member_ids = [ @cur_user.id ]
    @item.readable_custom_group_ids = []
  end

  def set_default_group
    @item.group_ids = []
    @item.user_ids = [ @cur_user.id ]
    @item.custom_group_ids = []
  end

  public

  def new
    if params[:source] && BSON::ObjectId.legal?(params[:source])
      source_item = @model.site(@cur_site).readable(@cur_user, site: @cur_site).find(params[:source])
      @item = @model.new_from_route(source_item)
    else
      @item = @model.new
    end
    @item.attributes = pre_params.merge(fix_params)

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @default_readable_setting = method(:set_default_readable_setting)
    @skip_default_group = true
  end

  def create
    @item = @model.new get_params
    unless @cur_user.gws_role_permit_any?(@cur_site, :public_readable_range_gws_workflow2_routes)
      set_default_readable_setting
      set_default_group
    end
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)
    render_create @item.save
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.readable_setting_range != "private"
      if !@cur_user.gws_role_permit_any?(@cur_site, :public_readable_range_gws_workflow2_routes)
        notice = I18n.t("mongoid.errors.models.gws/workflow2/route.readable_setting_range_error")
        redirect_to url_for(action: :show), notice: notice
        return
      end
    end

    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end
    render
  end

  def template
    @items = @model.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
    render
  end
end
