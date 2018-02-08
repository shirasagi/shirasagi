class Gws::Workflow::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::Form

  navi_view "gws/workflow/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow_label || t('modules.gws/workflow'), gws_workflow_setting_path]
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def publish
    set_item
    if @item.public?
      redirect_to({ action: :show }, { notice: t('gws/workflow.notice.published') })
      return
    end
    return if request.get?

    @item.state = 'public'
    render_opts = { render: { file: :publish }, notice: t('gws/workflow.notice.published') }
    render_update @item.save, render_opts
  end

  def depublish
    set_item
    if @item.closed?
      redirect_to({ action: :show }, { notice: t('gws/workflow.notice.depublished') })
      return
    end
    return if request.get?

    @item.state = 'closed'
    render_opts = { render: { file: :depublish }, notice: t('gws/workflow.notice.depublished') }
    render_update @item.save, render_opts
  end
end
