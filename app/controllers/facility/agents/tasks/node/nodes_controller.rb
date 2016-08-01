class Facility::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    ret = generate_node @node

    if @node.csv_assoc_enabled?
      @node.opendata_site_ids.each do |site_id|
        Opendata::Facility::AssocJob.bind(site_id: site_id).perform_later(@node.site.id, @node.id, ret ? true : false)
      end
    end
  end
end
