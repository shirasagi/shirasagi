class Gws::Memo::ForwardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Forward

  navi_view "gws/memo/messages/navi"

  before_action :deny_with_auth
  before_action :set_item, only: [:show, :edit, :update]

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_item
    @item = @model.user(@cur_user).site(@cur_site).first

    if @item.nil?
      @item = @model.new fix_params
      @item.save!
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [ t('mongoid.models.gws/memo/forward'), gws_memo_forwards_path ]
  end
end
