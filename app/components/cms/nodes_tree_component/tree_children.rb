class Cms::NodesTreeComponent::TreeChildren < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :site, :user, :children
end
