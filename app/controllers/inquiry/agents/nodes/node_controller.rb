class Inquiry::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Inquiry::ListHelper

  def index
    @items = Inquiry::Node::Form.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination(@items)

    items = @items.partition { |item| item.reception_enabled? && item.reception_close_date.present? }
    items[0] = items[0].sort_by do |item|
      item.reception_close_date.to_i
    end
    items[1] = items[1].sort_by do |item|
      if item.reception_start_date.present?
        item.reception_start_date.to_i
      else
        0
      end
    end

    @items = items.flatten
  end
end
