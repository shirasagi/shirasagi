class Gws::Circular::PostsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  before_action :check_member, only: :show

  navi_view "gws/circular/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/circular.tabs.post'), { action: :index, category: '-' }]
  end

  def set_items
    @items = @model.site(@cur_site).
      topic.
      without_deleted.
      and_public.
      member(@cur_user).
      search(@s).
      custom_order(@s.sort).
      page(params[:page]).per(50)
  end

  def check_member
    return if @item.member?(@cur_user)

    if @item.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to gws_circular_admin_path(id: @item)
      return
    end

    raise '403'
  end

  public

  def show
    raise '404' if @item.draft? || @item.deleted?

    if @item.see_type == 'simple' && @item.unseen?(@cur_user)
      @item.set_seen!(@cur_user)
    end
    render
  end
end
