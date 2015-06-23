class Ezine::Member
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission
  include Ezine::MemberSearchable
  include Ezine::Addon::Data

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
      [
        [I18n.t('ezine.options.email_type.text'), 'text'],
        [I18n.t('ezine.options.email_type.html'), 'html'],
      ]
    end

    def state_options
      [
        [I18n.t('ezine.options.delivery_state.enabled'), 'enabled'],
        [I18n.t('ezine.options.delivery_state.disabled'), 'disabled'],
      ]
    end

    def test_member?
      false
    end
end
