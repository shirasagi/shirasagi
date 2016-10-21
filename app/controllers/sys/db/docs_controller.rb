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
      @db = Mongoid.default_client
      @coll = @db[params[:coll]]
    end

    def set_item
      id = params[:id]
      if id =~ /^\d+$/
        id = id.to_i
      elsif id.length == 24
        id = BSON::ObjectId.from_string(id)
      end

      ## http://api.mongodb.com/ruby/current/Mongo/Collection.html
      raise "404" unless @item = @coll.find(_id: id).first
    end

  public
    def index
      raise "403" unless SS::User.allowed?(:edit, @cur_user)

      @items = @coll.find

      @fields = []
      @items.each { |item| @fields |= item.keys }
    end

    def show
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
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
