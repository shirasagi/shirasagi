class Gws::Workflow::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::Form

  navi_view "gws/workflow/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow_label || t('modules.gws/workflow'), gws_workflow_setting_path]
    @crumbs << [@model.model_name.human, url_for(action: :index)]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def create
    @item = @model.new get_params
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)

    result = @item.save

    create_opts = {}
    create_opts[:location] = gws_workflow_form_columns_path(form_id: @item) if result
    render_create result, create_opts
  end

  def publish
    set_item
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    if @item.public?
      redirect_to({ action: :show }, { notice: t('ss.notice.published') })
      return
    end
    return if request.get? || request.head?

    @item.state = 'public'
    render_opts = { render: { template: "publish" }, notice: t('ss.notice.published') }
    render_update @item.save, render_opts
  end

  def depublish
    set_item
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    if @item.closed?
      redirect_to({ action: :show }, { notice: t('ss.notice.depublished') })
      return
    end
    return if request.get? || request.head?

    @item.state = 'closed'
    render_opts = { render: { template: "depublish" }, notice: t('ss.notice.depublished') }
    render_update @item.save, render_opts
  end

  def copy
    set_item
    raise "404" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      @item.name = t("gws/notice.prefix.copy") + @item.name
      render
      return
    end

    service = Gws::Column::CopyService.new(cur_site: @cur_site, cur_user: @cur_user, model: @model, item: @item)
    service.overwrites = params.require(:item).permit(:name)
    service.overwrites[:state] = "closed"
    result = service.call
    if result
      @item = service.new_item
    else
      SS::Model.copy_errors(service, @item)
    end
    render_create result, render: { template: "copy" }, notice: t("ss.notice.copied")
  end
end
