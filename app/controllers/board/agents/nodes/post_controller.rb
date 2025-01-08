class Board::Agents::Nodes::PostController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Crud
  include SS::CaptchaFilter

  model Board::Post

  before_action :deny
  before_action :set_topic, only: [:new_reply, :reply]
  before_action :set_item, only: [:delete, :destroy]
  after_action :generate, only: [:create, :reply, :destroy]

  private

  def deny
    if @cur_node.deny_ips.present?
      remote_ip = remote_addr
      @cur_node.deny_ips.each do |deny_ip|
        raise SS::ForbiddenError if remote_ip.match?(/^#{deny_ip}/)
      end
    end
  end

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node, parent: @topic }
  end

  def set_topic
    @topic = @model.topic.site(@cur_site).
      where(id: params[:parent_id], node_id: @cur_node.id).first
    raise SS::NotFoundError unless @topic
  end

  def set_item
    @item = @model.site(@cur_site).
      where(id: params[:parent_id], node_id: @cur_node.id).first
    raise SS::NotFoundError unless @item
  end

  def generate
    return unless @item.errors.empty?
    SS::Agent.invoke_action "board/agents/tasks/node/posts", :generate, cur_node: @cur_node, node: @cur_node
  end

  public

  def index
    model = (@cur_node.mode == "tree") ? @model.topic : @model
    order = (@cur_node.mode == "tree") ? :descendants_updated : :updated
    @items = model.site(@cur_site).node(@cur_node).
      order(order => -1).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination(@items)
  end

  def create
    @item = @model.new get_params
    @item.valid? # for reporting all errors at once
    if @cur_node.captcha_enabled?
      captcha_valid?(@item)
    end
    if @item.errors.present?
      render action: :new
      return
    end

    render_create @item.save, location: "#{@cur_node.url}sent", render: :new
  end

  def new_reply
    @item = @model.new pre_params
    @item.name = "Re:#{@topic.name}"
  end

  def reply
    @item = @model.new get_params
    @item.valid? # for reporting all errors at once
    if @cur_node.captcha_enabled?
      captcha_valid?(@item)
    end
    if @item.errors.present?
      render action: :new_reply
      return
    end

    render_create @item.save, location: "#{@cur_node.url}sent", render: :new_reply
  end

  def delete
    raise SS::NotFoundError unless @cur_node.deletable_post?
    raise SS::NotFoundError unless @item.delete_key.present?
    @item.delete_key = ""
  end

  def destroy
    raise SS::NotFoundError unless @cur_node.deletable_post?
    raise SS::NotFoundError unless @item.delete_key.present?
    @item.delete_key = ""
    @item.attributes = get_params

    @item.valid? # for reporting all errors at once
    if @cur_node.captcha_enabled?
      if captcha_valid?(@item) && @item.delete_key_was == @item.delete_key
        render_destroy @item.destroy, location: "#{@cur_node.url}sent", render: :delete
        return
      else
        @item.errors.add :base, t("board.errors.not_same_delete_key") unless @item.delete_key_was == @item.delete_key
      end
    else
      if @item.delete_key_was == @item.delete_key
        render_destroy @item.destroy, location: "#{@cur_node.url}sent", render: :delete
        return
      else
        @item.errors.add :base, t("board.errors.not_same_delete_key") unless @item.delete_key_was == @item.delete_key
      end
    end

    @item.delete_key = ""
    render :delete
  end

  def search
    @items = []
    return if params[:keyword].blank?

    @words = params[:keyword].split(/[\s　]+/).uniq.compact
    @query = @words.map do |w|
      [ { name: /#{::Regexp.escape(w)}/ }, { text: /#{::Regexp.escape(w)}/ } ]
    end.flatten

    @items = @model.site(@cur_site).node(@cur_node).where("$or" => @query).
      page(params[:page]).
      per(@cur_node.limit)
  end
end
