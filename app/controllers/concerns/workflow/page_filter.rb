module Workflow::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  private

  def render_items(cond)
    if @cur_node
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        search(params[:s]).
        where(cond).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end
    @items = [] if !@items
    render file: :index
  end

  public

  def index_approve
    cond = {
      '$and' => [
        {
          workflow_state: "request",
          '$or' => [
            {
              workflow_approvers: {
                "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
              }
            }, {
              workflow_approvers: {
                "$elemMatch" => { "user_id" => @cur_user._id, "state" => "pending" }
              },
              workflow_pull_up: 'enabled'
            }
          ]
        }
      ]
    }
    render_items(cond)
  end

  def index_request
    render_items({ workflow_user_id: @cur_user._id })
  end

  def index_wait_close
    days = @cur_node.becomes_with_route.try(:close_days_before) || @cur_site.close_days_before || SS.config.cms.close_days_before
    days ||= 0
    cond = {
      state: 'public',
      :close_date.lt => Time.zone.now + days.days
    }
    render_items(cond)
  end

  def index_ready
    render_items({ state: "ready" })
  end

  def index_closed
    render_items({ state: "closed" })
  end
end
