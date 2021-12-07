module Gws::Memo::ExportAndBackupFilter
  extend ActiveSupport::Concern
  include Gws::BaseFilter
  include Gws::CrudFilter

  included do
    model Gws::Memo::Message

    navi_view "gws/memo/messages/navi"
    menu_view nil

    before_action :deny_with_auth
  end

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @item = @model.new
  end
end
