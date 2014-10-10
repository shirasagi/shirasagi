module Faq::Addons::Search
  class EditCell < Cell::Rails
    include SS::AddonFilter::EditCell
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
