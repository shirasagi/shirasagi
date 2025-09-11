#frozen_string_literal: true

module Gws::Notice::FoldersTreeComponent::Base
  extend ActiveSupport::Concern
  include SS::CacheableComponent
  include SS::MaterialIconsHelper

  TEMPLATE = <<~ERB
    <turbo-frame id="gws-notices-folder_tree-frame">
      <%= cache_component do %>
        <div class="content-navi-refresh">
          <%= link_to md_icons.outlined("refresh"), gws_notice_frames_folders_trees_path(mode: mode), title: I18n.t("ss.buttons.reload"), data: { turbo: true } %>
        </div>

        <div class="mb-2 tree-item<%= ' is-current' if @folder.blank? %>">
          <%= link_to t('gws/notice.all'), url_for(action: :index, folder_id: '-') %>
        </div>

        <%= render SS::TreeBaseComponent.new(root_nodes: root_nodes, css_class: "gws-notice-folders-tree") %>
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
      base_name = ::File.basename(folder.name)
      wrap = SS::TreeBaseComponent::NodeItem.new(
        id: folder.id, name: base_name, depth: folder.depth, updated: folder.updated, url: item_url(folder), children: [])
      parent_map[folder.name] = wrap
      if folder.depth == 1
        @root_nodes << wrap
        next
      end

      parent_name = ::File.dirname(folder.name)
      parent_wrap = parent_map[parent_name]
      unless parent_wrap
        Rails.logger.warn { "'#{folder.name}' hasn't parent node" }
        next
      end

      parent_wrap.children << wrap
    end

    @root_nodes
  end
end
