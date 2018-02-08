class Gws::Report::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/report/main/navi"
  model Gws::Report::Form

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_report_label || t('modules.gws/report'), gws_report_setting_path]
    @crumbs << [Gws::Report::Form.model_name.human, gws_report_forms_path]
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
