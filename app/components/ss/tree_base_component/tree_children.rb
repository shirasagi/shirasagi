class SS::TreeBaseComponent::TreeChildren < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :component, :children
end
