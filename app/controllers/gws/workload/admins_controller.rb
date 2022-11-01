class Gws::Workload::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::WorkFilter

  navi_view "gws/workload/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/workload.tabs.admin'), { action: :index, category: '-' }]
  end

  def set_items
    @items ||= @model.site(@cur_site).
      topic.
      without_deleted.
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50).
      custom_order(params.dig(:s, :sort) || 'due_date')
  end
end
