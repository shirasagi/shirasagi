class Lsorg::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View

  helper Lsorg::ListHelper

  def index
    root_groups = @cur_node.effective_root_groups
    exclude_groups = @cur_node.effective_exclude_groups

    @items = root_groups.map { |root_group| Lsorg::GroupTree.build(root_group, exclude_groups) }

    nodes = Lsorg::Node::Page.site(@cur_site).
      where(filename: /^#{@cur_node.filename}\//).to_a.index_by(&:filename)

    @items.each do |root|
      root.tree.each do |item|
        filename = ::File.join(@cur_node.filename, item.filename)
        item.node = nodes[filename]
      end
    end
  end
end
