class Facility::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View

  def index
    @items = Facility::Node::Page.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash)

    respond_to do |format|
      format.html
      format.csv do
        csv = @items.to_csv(public: true).encode("SJIS", invalid: :replace, undef: :replace)
        send_data csv, filename: "facilities_#{Time.zone.now.to_i}.csv"
      end
    end
  end
end
