class Ezine::Column
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission
  include Ezine::Addon::ColumnSetting

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :html, type: String, default: ""
  field :order, type: Integer, default: 0
  permit_params :state, :name, :html, :order

  belongs_to :node, class_name: "Ezine::Node::Page"

  validates :state, :name, presence: true
  before_destroy :destroy_data

  scope :and_public, -> {
    where(state: 'public')
  }

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

  private
    def destroy_data
      Ezine::Member.where(:"data.column_id" => id).each do |member|
        member.in_data[id.to_s] = nil
        member.set_data
        member.save validate: false
      end
      Ezine::Entry.where(:"data.column_id" => id).each do |entry|
        member.in_data[id.to_s] = nil
        member.set_data
        member.save validate: false
      end
    end
end
