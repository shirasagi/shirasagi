class Inquiry::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
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

  def answer_data(opts = {})
    node.answers.where(opts).
      map { |ans| ans.data.entries.select { |data| data.column_id == id } }.flatten
  end

  def state_options
    [
      [I18n.t('views.options.state.public'), 'public'],
      [I18n.t('views.options.state.closed'), 'closed'],
    ]
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end
end
