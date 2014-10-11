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
      render file: "app/views/cms/pages/index"
    end

  public
    def index_approve
      cond = {
        workflow_state: "request",
        workflow_approvers: {
          "$elemMatch" => { "user_id" => @cur_user._id, "state" => "request" }
        }
      }
      render_items(cond)
    end

    def index_request
      cond = { workflow_user_id: @cur_user._id }
      render_items(cond)
    end

    def index_ready
      cond = { state: "ready" }
      render_items(cond)
    end

    def index_closed
      cond = { state: "closed" }
      render_items(cond)
    end

end
