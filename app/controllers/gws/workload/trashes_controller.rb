class Gws::Workload::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::WorkFilter

  navi_view "gws/workload/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/workload.tabs.trash'), { action: :index, category: '-' }]
  end

  def set_items
    @items ||= @model.site(@cur_site).
      topic.
      only_deleted.
      allow(:trash, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
