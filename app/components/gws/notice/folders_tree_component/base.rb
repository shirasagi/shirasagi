#frozen_string_literal: true

module Gws::Notice::FoldersTreeComponent::Base
  extend ActiveSupport::Concern
  include SS::CacheableComponent
  include SS::MaterialIconsHelper

  TEMPLATE = <<~ERB
    <turbo-frame id="gws-notice-folder_tree-frame">
      <%= cache_component do %>
        <div class="content-navi-refresh">
          <%= link_to md_icons.outlined("refresh"), gws_notice_frames_folders_trees_path(mode: mode), title: I18n.t("ss.buttons.reload"), data: { turbo: true } %>
        </div>

        <div class="mt-2 mb-2 gws-notice-folder_tree-menu">
          <%= link_to t('gws/notice.all'), url_for(controller: "/gws/notice/\#{mode.pluralize}", action: :index, folder_id: '-'), data: { turbo: false } %>
        </div>

        <%= render SS::TreeBaseComponent.new(root_nodes: root_nodes, css_class: "gws-notice-folder_tree") %>
      <% end %>
    </turbo-frame>
  ERB

  class TreeBuilder < Gws::GroupTreeComponent::TreeBuilder
    include ActiveModel::Model

    attr_accessor :expands

    def new_node_item(group, depth:)
      opens = expands ? true : false
      SS::TreeBaseComponent::NodeItem.new(
        id: group.id, name: group.name, depth: depth, updated: group.updated,
        url: item_url_p.call(group), opens: opens, children: [])
    end

    def update_node_item(node, depth:, name:, **_optional_kw_args)
      if node.depth == depth && node.name == name
        node
      else
        node.with(depth: depth, name: name)
      end
    end
  end

  included do
    attr_accessor :cur_site, :cur_user

    self.cache_key = -> do
      results = folders.aggregates(:updated)
      [ cur_site.id, cur_user.id, results["count"], results["max"].to_i ]
    end

    erb_template TEMPLATE
  end

  def mode
    @mode ||= ::File.basename(self.class.name.underscore)
  end

  def root_nodes
    @root_nodes ||= begin
      builder = TreeBuilder.new(
        items: folders, item_url_p: method(:item_url), expands: cur_site.notice_folder_navi_expand_all?)
      builder.call
    end
  end
end
