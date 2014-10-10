class Sys::Db::DocsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  before_action :set_db, prepend: true

  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"sys.db_tool", sys_db_path]
      @crumbs << [@coll.name, sys_db_docs_path(coll: @coll.name)]
    end

    def set_db
      @db = SS::User.collection.database
      @coll = @db[params[:coll]]
    end

    def set_item
      id = params[:id]
      id = id.to_i if id =~ /^\d+$/

      ## http://rdoc.info/github/mongoid/moped/Moped/Query
      raise "404" unless @item = @coll.find(_id: id).one
    end

  public
    def index
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)

      @items = @coll.find

      @fields = []
      @items.each { |item| @fields |= item.keys }
    end

    def show
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)
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
