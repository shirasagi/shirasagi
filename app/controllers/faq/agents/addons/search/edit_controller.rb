module Faq::Agents::Addons::Search
  class EditController < ApplicationController
    include SS::AddonFilter::Edit
    helper_method :search_node_options

    private
      def search_node_options
        opts = []
        Faq::Node::Search.site(@cur_site).each do |node|
          opts << [ node.name, node.id ]
        end
        opts
      end
  end
end
