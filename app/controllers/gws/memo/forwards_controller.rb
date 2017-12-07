class Gws::Memo::ForwardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  #include Gws::SettingFilter

  model Gws::Memo::Forward

  private

  # def set_item
  #   @item = @cur_site
  # end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('ss.management'), gws_memo_management_main_path ]
    @crumbs << [t('mongoid.models.gws/memo/forward'), gws_memo_forwards_path ]
  end

  public

  # def show
  #   raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  #   super
  # end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

end