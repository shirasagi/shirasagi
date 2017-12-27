class Gws::Memo::ForwardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Forward

  before_action :deny_with_auth
  before_action :set_item, only: [:show, :edit, :update]

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_item
    if @model.user(@cur_user).present?
      @item = @model.find_by(user_id: @cur_user.id)
    else
      @item = @model.new(user_id: @cur_user.id)
      @item.site = @cur_site
      @item.save
    end
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('ss.management'), gws_memo_management_main_path ]
    @crumbs << [t('mongoid.models.gws/memo/forward'), gws_memo_forwards_path ]
  end

  public

  def index
    @items = @model.user(@cur_user).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
