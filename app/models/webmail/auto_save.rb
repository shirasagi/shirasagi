class Webmail::AutoSave
  include SS::Document
  include SS::Reference::User
  include Webmail::Addon::MailFile

  MAX_RESTORABLE = 10
  AUTO_SAVE_KEYWORD = "$SSautoSave".freeze

  attr_accessor :imap

  field :account, type: String
  field :state, type: String, default: "temporary"
  field :draft_uid, type: Integer

  ## header
  field :to, type: Array, default: []
  field :cc, type: Array, default: []
  field :bcc, type: Array, default: []
  field :reply_to, type: Array, default: []

  ## body
  field :subject, type: String
  field :format, type: String
  field :text, type: String
  field :html, type: String

  ## files
  embeds_ids :files, class_name: "SS::File"
  field :draft_ref_file_ids, type: Array, default: []

  permit_params to: [], cc: [], bcc: [], reply_to: []
  permit_params :draft_uid, :subject, :format, :text, :html
  permit_params file_ids: []

  validates :account, presence: true
  validates :user_id, presence: true
  validate :validate_addresses
  validate :validate_ref_file_ids

  default_scope -> { order_by(update: -1) }

  def in_request_mdn
    nil
  end

  def in_request_dsn
    nil
  end

  def message_id
    nil
  end

  def merge_address_field(array, str)
    (array + str.to_s.split(";")).uniq.select { |c| c.present? }.compact
  end

  def mail_attributes
    assign_fields = %w(to cc bcc reply_to subject format text html file_ids)
    imap.account_scope.
      merge(cur_user: user, mailbox: imap.draft_box, imap: imap).
      merge(self.attributes.slice(*assign_fields)).
      merge(ref_file_uid: draft_uid, ref_file_ids: draft_ref_file_ids)
  end

  def save_draft
    item = Webmail::Mail.new
    item.attributes = mail_attributes
    self.destroy if item.save_draft(updated, [AUTO_SAVE_KEYWORD])
  end

  # 以下は、下書きの自動保存を復元した際に、元の下書きを上書きするパターン
  #def save_draft
  #  if draft_uid
  #    begin
  #      imap.select(imap.draft_box)
  #      if SS.config.webmail.store_mails
  #        item = imap.mails.find_and_store(draft_uid, :body)
  #      else
  #        item = imap.mails.find(draft_uid, :body)
  #      end
  #    rescue => e
  #      Rails.logger.error("#{self.class} #save_draft : find draft original mail failed")
  #    end
  #  end
  #
  #  item ||= Webmail::Mail.new
  #  item.attributes = mail_attributes
  #  self.destroy if item.save_draft(updated)
  #end

  def ready!
    self.class.where(id: id, state: { "$in" => %w(temporary ready) }).find_one_and_update({ '$set' => { state: "ready" } })
    reload
  end

  # 編集/送信が終わった際に auto_save を destroy したいが、
  # 別リクエスト（ajax）で save を実行している可能性があるのでステータスを discarded に固定して、後で destroy する
  def discard!
    self.class.where(id: id).find_one_and_update({ '$set' => { state: "discarded" } })
    reload
  end

  private

  def validate_addresses
    self.to = to.select(&:present?) if to.present?
    self.cc = cc.select(&:present?) if cc.present?
    self.bcc = bcc.select(&:present?) if bcc.present?
  end

  def validate_ref_file_ids
    self.draft_ref_file_ids = ref_file_ids
  end

  class << self
    def user_account(user, account)
      self.user(user).where(account: account)
    end

    def create_temporary(cur_user:, account:)
      item = self.new
      item.cur_user = cur_user
      item.account = account
      item.save
      item
    end

    def destroy_unused_items(cur_user:, account:)
      self.user_account(cur_user, account).in(state: %w(temporary discarded)).destroy_all
    end

    def save_draft(cur_user:, account:, imap:)
      count = 0
      self.user_account(cur_user, account).where(state: "ready").each do |item|
        if count < MAX_RESTORABLE
          item.imap = imap
          item.save_draft
        else
          item.destroy
        end
        count += 1
      end
    end
  end
end
