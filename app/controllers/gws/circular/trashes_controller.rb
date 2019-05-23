class Gws::Circular::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  navi_view "gws/circular/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/circular.tabs.trash'), action: :index]
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
