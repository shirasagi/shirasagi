class Gws::Memo::ForwardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Forward

  before_action :set_item, only: [:show, :edit, :update]

  private

  def set_item
   if @model.user(@cur_user).site(@cur_site).present?
     @item = @model.find_by(user_id: @cur_user.id, site_id: @cur_site.id)
   else
     @item = @model.new(user_id: @cur_user.id, site_id: @cur_site.id)
     @item.save
   end
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('ss.management'), gws_memo_management_main_path ]
    @crumbs << [t('mongoid.models.gws/memo/forward'), gws_memo_forwards_path ]
  end

  public

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    super
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    super
  end

  def update
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    super
  end
end
