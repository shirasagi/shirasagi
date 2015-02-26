class Ezine::Member
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Permission
  include Ezine::MemberSearchable

  field :email, type: String, metadata: { from: :email }
  field :email_type, type: String
  field :state, type: String, default: 'enabled'

  permit_params :email, :email_type, :state

  belongs_to :node, class_name: "Cms::Node"

  validates :email, uniqueness: { scope: :node_id }, presence: true, email: true
  validates :email_type, inclusion: { in: %w(text html) }
  validates :state, inclusion: { in: %w(enabled disabled) }

  scope :enabled, ->{ where(state: 'enabled') }

  public
    def email_type_options
      [%w(テキスト版 text), %w(HTML版 html)]
    end

    def state_options
      [%w(配信する enabled), %w(配信しない disabled)]
    end

    def test_member?
      false
    end
end
