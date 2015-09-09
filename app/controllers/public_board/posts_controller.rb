class PublicBoard::PostsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model PublicBoard::Post

  navi_view "public_board/main/navi"

  before_action :set_topic, only: [:new_reply, :reply]
  after_action :generate, only: [:create, :reply, :update, :destroy]

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node, cur_user: @cur_user, parent: @topic }
    end

    def set_topic
      @topic = @model.topic.site(@cur_site).
        where(id: params[:id], node_id: @cur_node.id).first
      raise "403" unless @topic
    end

    def generate
      return unless @item.errors.empty?

      cur_node = @cur_node.becomes_with_route
      agent = SS::Agent.new PublicBoard::Agents::Tasks::Node::PostsController
      agent.controller.instance_variable_set :@cur_node, cur_node
      agent.controller.instance_variable_set :@node, cur_node
      agent.invoke(:generate)
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

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
      render_create @item.save, location: { action: :index }, render: { file: :new_reply }
    end

    def download
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      csv = @model.site(@cur_site).node(@cur_node).order(updated: -1).to_csv
      send_data csv.encode("SJIS"), filename: "board_posts_#{Time.zone.now.to_i}.csv"
    end
end
