class Board::PostsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Board::Post

  navi_view "board/main/navi"

  before_action :check_node_permission
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_topic, only: [:new_reply, :reply, :edit, :update]
  after_action :generate, only: [:create, :reply, :update, :destroy]

  private

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node, cur_user: @cur_user, parent: @topic }
  end

  def check_node_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  def set_topic
    @topic = @model.topic.site(@cur_site).
      where(id: params[:id], node_id: @cur_node.id).first
    @topic = @item.topic if @item
  end

  def generate
    return unless @item.errors.empty?

    SS::Agent.invoke_action "board/agents/tasks/node/posts", :generate, cur_node: @cur_node, node: @cur_node
  end

  public

  def index
    @items = @model.topic.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user, site: @cur_site).
      order(descendants_updated: -1).
      page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_create @item.save, location: { action: :index }
  end

  def new_reply
    @item = @model.new
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.name = "Re:#{@topic.name}"
  end

  def reply
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_create @item.save, location: { action: :index }, render: { template: "new_reply" }
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    criteria = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user, site: @cur_site, node: @cur_node)
    csv = criteria.order(updated: -1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "board_posts_#{Time.zone.now.to_i}.csv"
  end
end
