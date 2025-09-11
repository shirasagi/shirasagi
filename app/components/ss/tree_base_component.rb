class SS::TreeBaseComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :root_nodes, :css_class

  renders_one :header

  NodeItem = Data.define(:id, :name, :depth, :updated, :url, :children) do
    def children?
      children.present?
    end
  end
end
