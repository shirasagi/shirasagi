class Gws::Memo::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Folder

  navi_view "gws/memo/messages/navi"

  before_action :deny_with_auth

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_item
    super
    raise "404" if @item.user_id != @cur_user.id
    raise "404" if @item.site_id != @cur_site.id
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('mongoid.models.gws/memo/folder'), gws_memo_folders_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.user(@cur_user).
      site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50).tree_sort
  end

  def create
    @item = @model.new get_params
    @item.attributes["action"] = params["action"]
    if @item.in_parent.present?
      parent_folder = @model.where(site_id: @cur_site.id, id: @item.in_parent).first
    end
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end
end
