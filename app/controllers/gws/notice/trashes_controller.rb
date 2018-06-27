class Gws::Notice::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_items
  before_action :set_item, only: [:show, :delete, :destroy, :undo_delete]
  before_action :set_selected_items, only: [:destroy_all, :soft_delete_all]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), gws_notice_main_path]
    @crumbs << [t('ss.navi.trash'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      only_deleted.
      search(params[:s])
  end

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @items = @items.in(id: ids)
    raise "400" unless @items.present?
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end
end
