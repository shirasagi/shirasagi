class Guide2::Question
  # include Mongoid::Document
  include SS::Document

  field :type, type: String, default: 'yes_no'
  field :name, type: String
  #field :group_name, type: String
  field :order, type: Integer
  embedded_in :parent, class_name: "Guide2::Node::Question"

  # validates :name, presence: true

  class << self
    def table_fields
      [:name, :order]
    end
  end
end
