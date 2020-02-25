class Gws::Discussion::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Forum

  navi_view 'gws/discussion/main/navi'
  append_view_path 'app/views/gws/discussion/forums'

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_main_path ]
    @crumbs << [ I18n.t('ss.navi.trash'), action: :index ]
  end

  def pre_params
    super.merge member_ids: [@cur_user.id]
  end

  public

  def index
    raise "403" unless @model.allowed?(:trash, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).forum.only_deleted
    @items = @items.allow(:trash, @cur_user, site: @cur_site)
    @items.search(params[:s]).
      reorder(order: 1, created: 1).
      page(params[:page]).per(50)
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  # def destroy
  #   raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
  #   render_destroy @item.destroy
  # end
  #
  # def destroy_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:delete, @cur_user, site: @cur_site)
  #       next if item.destroy
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end
end
