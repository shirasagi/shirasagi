class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission
  include Inquiry::Addon::InputSetting

  seqid :id
  field :node_id, type: Integer
  field :state, type: String, default: "public"
  field :name, type: String
  field :html, type: String, default: ""
  field :order, type: Integer, default: 0

  belongs_to :node, foreign_key: :node_id, class_name: "Inquiry::Node::Form"

  permit_params :id, :node_id, :state, :name, :html, :order

  validates :node_id, :state, :name, presence: true

  public
    def state_options
      [ %w(公開 public), %w(非公開 closed) ]
    end

    def order
      value = self[:order].to_i
      value < 0 ? 0 : value
    end
end
