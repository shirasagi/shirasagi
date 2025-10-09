class SS::TreeBaseComponent::TreeChildren < ApplicationComponent
  include ActiveModel::Model
  include SS::DateTimeHelper

  attr_accessor :component, :children, :shows_updated
end
