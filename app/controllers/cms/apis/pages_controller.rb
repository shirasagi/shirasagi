class Cms::Apis::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  before_action :set_search_params
  before_action :set_selected_node
  helper_method :statuses_option

  KNOWN_STATUSES = %w(public ready request remand draft closed).freeze

  private

  def set_search_params
    @s = begin
      s = OpenStruct.new(params[:s])

      # normalize statuses
      s.statuses = Array(s.statuses).flatten.map(&:to_s).select(&:present?)
      if s.statuses.blank?
        # set default statuses
        s.statuses = KNOWN_STATUSES
      else
        # sanitize statuses
        s.statuses &= KNOWN_STATUSES
      end

      s
    end
  end

  def set_selected_node
    node_id = @s.node
    if node_id.present? && node_id != "all"
      @selected_node = Cms::Node.site(@cur_site).where(id: node_id.to_s).first
      @selected_node = @selected_node.becomes_with_route if @selected_node
    end
  end

  def statuses_option
    KNOWN_STATUSES.map do |v|
      [ t("ss.state.#{v}"), v ]
    end
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site)
    if @selected_node.present?
      @items = @items.where(filename: /^#{::Regexp.escape(@selected_node.filename)}\//)
    end
    if (KNOWN_STATUSES - @s.statuses).present?
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
        when "draft"
          conds << {
            state: "closed", :first_released.exists => false,
            :workflow_state.ne => "request", :workflow_state.ne => "remand"
          }
        when "closed"
          conds << {
            state: "closed", :first_released.exists => true,
            :workflow_state.ne => "request", :workflow_state.ne => "remand"
          }
        end
      end

      @items = @items.where("$and" => [{ "$or" => conds }])
    end

    @items = @items.search(@s).
      order_by(_id: -1).
      page(params[:page]).per(50)

    if params[:layout] == "iframe"
      render layout: "ss/ajax_in_iframe"
    end
  end

  def routes
    @items = @model.routes
  end
end
