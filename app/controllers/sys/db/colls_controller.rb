class Sys::Db::CollsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  menu_view nil
  helper_method :db

  private

  def db
    @db ||= begin
      raise "404" unless SS::User.allowed?(:edit, @cur_user)
      Mongoid.default_client
    end
  end

  def set_crumbs
    @crumbs << [ t("sys.db_tool"), sys_db_path ]
  end

  public

  def index
    @items = db.collections
    @items = @items.sort_by { |item| item.name }
  end

  def new
    raise
  end

  def create
    raise
  end

  def update
    raise
  end

  def destroy
    raise
  end

  def info
    render
  end
end
