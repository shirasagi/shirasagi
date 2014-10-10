class Sys::Db::CollsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  before_action :set_db

  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"sys.db_tool", sys_db_path]
    end

    def set_db
      @db = SS::User.collection.database
    end

  public
    def index
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)

      @items = @db.collections
      @items = @items.select {|m| m.name !~ /^fs\./ }
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
end
