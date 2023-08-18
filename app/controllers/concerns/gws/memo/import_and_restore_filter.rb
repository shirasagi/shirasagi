module Gws::Memo::ImportAndRestoreFilter
  extend ActiveSupport::Concern
  include Gws::BaseFilter
  include Gws::CrudFilter

  included do
    navi_view "gws/memo/messages/navi"
    menu_view nil

    before_action :deny_with_auth
  end

  private

  def deny_with_auth
    raise "403" unless Gws::Memo::Message.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @model.new
  end

  def set_item
    @item = @model.new

    file = params.dig(:item, :in_file)
    if file.nil?
      @item.errors.add :in_file, :blank
      render action: :index
      return
    end
    if ::File.extname(file.original_filename) != ".zip"
      @item.errors.add :in_file, :invalid_file_type
      render action: :index
      return
    end

    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    @item.in_file = file
  end
end
