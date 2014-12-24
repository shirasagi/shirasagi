class Ezine::Agents::Nodes::FormController < ApplicationController
  include Cms::NodeFilter::View

  public
    def entry
      @model = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
      render action: :entry
    end

    def update
      @model = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
      render action: :update
    end

    def remove
      @model = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
      render action: :remove
    end

    def create
      if params[:submit].present?
        # TODO: save process
      else
        render action: :entry
      end
    end
end
