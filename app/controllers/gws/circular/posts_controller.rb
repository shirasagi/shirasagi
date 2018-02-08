class Gws::Circular::PostsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  navi_view "gws/circular/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/circular.tabs.post'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).
      topic.
      without_deleted.
      and_public.
      member(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  public

  def show
    raise '404' if @item.draft? || @item.deleted?
    raise '403' unless @item.member?(@cur_user)
    if @item.see_type == 'simple' && @item.unseen?(@cur_user)
      @item.set_seen(@cur_user).save
    end
    render
  end
end
