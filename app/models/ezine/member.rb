class Ezine::Member
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Permission
  include Ezine::MemberSearchable

  field :email, type: String, metadata: { from: :email }
  field :email_type, type: String
  field :state, type: Boolean, default: true

  permit_params :email, :email_type, :state

  belongs_to :node, class_name: "Cms::Node"

  validates :email, uniqueness: { scope: :node_id }, presence: true, email: true

  public
    def email_type_options
      [%w(テキスト版 text), %w(HTML版 html)]
    end

    def state_options
      [%w(有効 true), %w(無効 false)]
    end

    def test_member?
      false
    end
end
