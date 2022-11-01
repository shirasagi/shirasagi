class Gws::Workload::WorksController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::WorkFilter

  navi_view "gws/workload/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/workload.tabs.work'), { action: :index, category: '-' }]
  end

  def set_items
    @items = @model.site(@cur_site).
      topic.
      without_deleted.
      and_public.
      member(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50).
      custom_order(params.dig(:s, :sort) || 'due_date')
  end

  public

  def show
    raise '404' if @item.draft? || @item.deleted?
    raise '403' unless @item.member?(@cur_user)

    render
  end
end
