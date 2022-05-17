class Sys::Db::DocsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  menu_view nil
  helper_method :db, :coll

  before_action :set_search, only: :index

  private

  def db
    @db ||= begin
      raise "404" unless SS::User.allowed?(:edit, @cur_user)
      Mongoid.default_client
    end
  end

  def coll
    @coll ||= db[params[:coll]]
  end

  def set_crumbs
    @crumbs << [ t("sys.db_tool"), sys_db_path ]
    @crumbs << [ coll.name, sys_db_docs_path(coll: coll.name) ]
  end

  def set_search
    @s ||= OpenStruct.new params[:s]
  end

  def set_item
    id = params[:id]
    if id.numeric? && !BSON::ObjectId.legal?(id)
      id = id.to_i
    elsif id.length == 24
      id = BSON::ObjectId.from_string(id)
    end

    ## http://api.mongodb.com/ruby/current/Mongo/Collection.html
    raise "404" unless @item = coll.find(_id: id).first
  end

  public

  def index
    limit = 50
    page = params[:page].try { |page| page.to_i - 1 } || 0
    offset = page * limit

    if @s.filter.present?
      begin
        filter = ExecJS.eval(@s.filter)
      rescue => e
        @filter_error = e.to_s
        render
        return
      end
    end

    @items = coll.find(filter, limit: limit, skip: offset)
    total_count = @items.count
    @items = Kaminari.paginate_array(@items.to_a, limit: limit, offset: offset, total_count: total_count)

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

  def indexes
    render
  end

  def stats
    render
  end
end
