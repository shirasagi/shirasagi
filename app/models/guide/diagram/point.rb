class Guide::Diagram::Point
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node

  attr_accessor :transitions
  attr_accessor :weight

  default_scope -> { order_by(_type: -1, order: 1, name: 1) }

  store_in collection: "guide_diagram_point"

  def procedure?
    self._type == "Guide::Procedure"
  end

  def question?
    self._type == "Guide::Question"
  end
end
