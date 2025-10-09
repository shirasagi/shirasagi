class SS::TreeBaseComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::DateTimeHelper

  attr_accessor :root_nodes, :css_class, :shows_updated

  renders_one :header
  renders_one :tree_header

  NodeItem = Data.define(:id, :name, :depth, :updated, :url, :opens, :children) do
    def children?
      children.present?
    end
  end
end
