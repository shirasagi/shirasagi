class Webmail::Signature
  include SS::Document
  include SS::Reference::User
  include Webmail::ImapPermission

  field :host, type: String
  field :account, type: String
  field :name, type: String
  field :text, type: String
  field :default, type: String, default: 'disabled'

  permit_params :name, :text, :default

  validates :host, presence: true
  validates :account, presence: true
  validates :name, presence: true
  validates :text, presence: true

  after_save :check_default, if: ->{ default? }

  default_scope -> { order_by name: 1 }

  scope :default, -> { where default: 'enabled' }

  scope :and_imap, ->(imap) {
    where imap.account_scope
  }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  class << self
    def default_sign(imap)
      sign = self.where(imap.account_scope).default.first
      sign ? sign.text.presence : nil
    end

    def signature_options(imap)
      self.where(imap.account_scope).map do |c|
        [c.name, c.text]
      end
    end
  end

  def default_options
    %w(enabled disabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def default?
    default == "enabled"
  end

  private

  def check_default
    self.class.
      where(host: host, account: account, default: 'enabled').
      where(:id.ne => id).
      update_all(default: 'disabled')
  end
end
