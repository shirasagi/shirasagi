class Gws::Memo::SignaturesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Signature

  before_action :deny_with_auth

  private

  def set_item
    super
    raise "404" if @item.user_id != @cur_user.id
  end

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('ss.management'), gws_memo_management_main_path ]
    @crumbs << [t('mongoid.models.gws/memo/signature'), gws_memo_signatures_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
