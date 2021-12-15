module Cms::Apis::PageFilter
  extend ActiveSupport::Concern

  KNOWN_STATUSES = %w(public ready request remand edit closed).freeze

  included do
    before_action :set_search_params
    before_action :set_parent_nodes
    before_action :set_selected_node
    before_action :set_items
    helper_method :statuses_option
  end

  private

  def set_parent_nodes
    ids = params[:parent_nodes].to_a.map(&:to_i) rescue []
    if ids.present?
      items = Cms::Node.in(id: ids).to_a
      items = ids.map { |id| items.find { |item| item.id == id } }
      @parent_nodes = items
    else
      @parent_nodes = []
    end
    @selected_node = @parent_nodes.first
  end

  def set_search_params
    @single = params[:single].present?
    @multi = !@single
    @dropdown = (params[:dropdown] == "select") ? "select" : "tree"

    @s = begin
      s = OpenStruct.new(params[:s])

      # normalize statuses
      s.statuses = Array(s.statuses).flatten.map(&:to_s).select(&:present?)
      if s.statuses.blank?
        # set default statuses
        s.statuses = KNOWN_STATUSES - %w(closed)
      else
        # sanitize statuses
        s.statuses &= KNOWN_STATUSES
      end

      s.category_ids = Array(s.category_ids).flatten.select(&:present?).map(&:to_i)

      s
    end
  end

  def set_selected_node
    node_id = @s.node
    if node_id.present? && node_id != "all"
      @selected_node = Cms::Node.site(@cur_site).where(id: node_id.to_s).first
    end
  end

  def set_items
    @items = @model.site(@cur_site).exists(master_id: false)

    set_select_items
    set_statuses_items

    @items = @items.search(@s)
  end

  def set_select_items
    return unless @selected_node
    @items = @items.where(filename: /^#{::Regexp.escape(@selected_node.filename)}\//)
  end

  def set_statuses_items
    return if (KNOWN_STATUSES - @s.statuses).blank?
    conds = []
    @s.statuses.each do |status|
      case status
      when "public"
        conds << { state: "public" }
      when "ready"
        conds << { state: "ready" }
      when "request"
        conds << { state: "closed", workflow_state: "request" }
      when "remand"
        conds << { state: "closed", workflow_state: "remand" }
      when "edit"
        conds << {
          state: "closed", :first_released.exists => false,
          :workflow_state.exists => false
        }
      when "closed"
        conds << {
          state: "closed", :first_released.exists => true,
          :workflow_state.exists => false
        }
      end
    end
    @items = @items.where("$and" => [{ "$or" => conds }])
  end

  public

  def statuses_option
    KNOWN_STATUSES.map do |v|
      [ t("ss.state.#{v}"), v ]
    end
  end
end
