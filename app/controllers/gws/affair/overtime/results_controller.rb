class Gws::Affair::Overtime::ResultsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include SS::AjaxFilter

  model Gws::Affair::OvertimeFile

  def set_item
    @item = Gws::Affair::OvertimeFile.site(@cur_site).find(params[:id])
    @item.cur_user = @cur_user

    @user = @item.target_user
    @site = @item.site
    @date = @item.date

    @items = @files = Gws::Affair::OvertimeFile.site(@site).where(
      target_user: @user.id,
      workflow_state: "approve",
      date: @date
    ).exists(result_closed: false).reorder(start_at: 1)
  end

  def update
    @item.attributes = get_params
    render_update @item.save_results, location: params[:ref]
  end

  def close
    set_item

    url = params[:ref]
    @item.close_result
    redirect_to url, notice: I18n.t("gws/affair.notice.close_results")
  end
end
