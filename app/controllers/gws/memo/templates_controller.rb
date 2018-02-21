class Gws::Memo::TemplatesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Template

  navi_view "gws/memo/messages/navi"

  before_action :deny_with_auth

  private

  def set_item
    super
    raise "404" if @item.site_id != @cur_site.id
  end

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('mongoid.models.gws/memo/template'), gws_memo_templates_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.
      site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
