class Webmail::Filter
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission
  include Webmail::Addon::ApplyFilter

  APPLY_PER = 2 # 100

  field :name, type: String
  field :state, type: String
  field :order, type: Integer, default: 0
  field :from, type: String
  field :to, type: String
  field :subject, type: String
  field :action, type: String
  field :mailbox, type: String

  permit_params :name, :state, :order, :from, :to, :subject, :action, :mailbox

  validates :name, presence: true
  validates :action, presence: true
  validates :mailbox, presence: true, if: ->{ action =~ /move|copy/ }

  validate :validate_conditions

  default_scope -> { order_by order: 1 }

  scope :enabled, -> { where state: 'enabled' }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  def imap
    self.class.imap
  end

  def state_options
    %w(enabled disabled).map { |m| [I18n.t("views.options.state.#{m}"), m] }
  end

  def action_options
    %w(move copy delete).map { |m| [I18n.t("webmail.options.action.#{m}"), m] }
  end

  def mailbox_options
    Webmail::Mailbox.user(@cur_user).to_options
  end

  def decode_mailbox
    Net::IMAP.decode_utf7(mailbox).sub(/^INBOX\./, '')
  end

  def search_keys
    keys = []
    %w(from to subject).each do |key|
      keys += [key.upcase, send(key)] if send(key).present?
    end
    keys
  end

  def apply_recent
    src_mailbox = 'INBOX'
    imap.conn.select(src_mailbox)
    uids = imap.conn.uid_sort(['DATE'], ['NEW'] + search_keys, 'UTF-8')
    uids_apply(uids, src_mailbox)
  end

  def apply_mailbox(src_mailbox)
    imap.conn.select(src_mailbox)
    uids = imap.conn.uid_sort(['DATE'], search_keys, 'UTF-8')
    uids_apply(uids, src_mailbox)
  end

  def uids_apply(uids, src_mailbox)
    count = 0

    uids.each_slice(APPLY_PER) do |sliced_uids|
      applied_uids = []

      sliced_uids.each do |uid|
        next unless uid_apply(uid)
        applied_uids << uid
        count += 1
      end

      if applied_uids.present? && action =~ /move|delete/
        imap.conn.expunge
        Webmail::Mail.where(imap.cache_key).
          where(mailbox: src_mailbox, :uid.in => applied_uids).
          destroy
      end
    end

    count
  end

  def uid_apply(uid)
    begin
      if action == "move"
        imap.conn.uid_copy(uid, mailbox)
        imap.conn.uid_store(uid, '+FLAGS', [:Deleted])
      elsif action == "copy"
        imap.conn.uid_copy(uid, mailbox)
      elsif action == "delete"
        imap.conn.uid_store(uid, '+FLAGS', [:Deleted])
      end
      true
    rescue Net::IMAP::NoResponseError => e
      raise e if Rails.env.development?
      false
    end
  end

  private
    def validate_conditions
      %w(from to subject).each do |key|
        return if send(key).present?
      end
      errors.add :base, I18n.t("webmail.errors.blank_conditions")
    end

  class << self
    def imap
      Webmail::Mail.imap
    end
  end
end
