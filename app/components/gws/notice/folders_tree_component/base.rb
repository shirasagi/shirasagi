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
    return @root_nodes if @root_nodes
    build_tree
  end

  private

  def build_tree
    @root_nodes = []
    parent_map = {}

    folders.to_a.each do |folder|
      folder.site = folder.cur_site = cur_site

      if folder.depth == 1
        wrap = SS::TreeBaseComponent::NodeItem.new(
          id: folder.id, name: folder.name, depth: folder.depth, updated: folder.updated, url: item_url(folder), children: [])
        @root_nodes << wrap
        parent_map[folder.name] = wrap
        next
      end

      name_parts = folder.name.split("/")
      split_pos = name_parts.length - 1
      found = false
      while split_pos > 0
        parent_name = name_parts[0..(split_pos - 1)].join("/")
        base_name = name_parts[split_pos..- 1].join("/")
        parent_wrap = parent_map[parent_name]

        split_pos -= 1

        if parent_wrap
          wrap = SS::TreeBaseComponent::NodeItem.new(
            id: folder.id, name: base_name, depth: folder.depth, updated: folder.updated, url: item_url(folder), children: [])
          parent_wrap.children << wrap
          parent_map[folder.name] = wrap
          found = true
          break
        end
      end

      unless found
        wrap = SS::TreeBaseComponent::NodeItem.new(
          id: folder.id, name: folder.name, depth: folder.depth, updated: folder.updated, url: item_url(folder), children: [])
        @root_nodes << wrap
        parent_map[folder.name] = wrap
      end
    end

    @root_nodes
  end
end
