class Webmail::Filter
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission
  include Webmail::ImapAccessor
  include Webmail::Addon::ApplyFilter

  # 一括処理件数
  APPLY_PER = 100

  field :host, type: String
  field :account, type: String
  field :mailbox, type: String

  field :name, type: String
  field :state, type: String, default: 'enabled'
  field :order, type: Integer, default: 0

  field :conditions, type: Array, default: []
  field :action, type: String

  permit_params :host, :account, :mailbox, :name, :state, :order, :action
  permit_params conditions: [:field, :operator, :value]

  validates :name, presence: true
  validates :conditions, presence: true
  validates :action, presence: true
  validates :mailbox, presence: true, if: ->{ action =~ /copy|move/ }

  before_validation :set_conditions

  default_scope -> { order_by order: 1 }

  scope :imap_setting, ->(user, setting) {
    conf = setting.imap_settings(user.imap_default_settings)
    where host: conf[:host], account: conf[:account]
  }

  scope :enabled, -> { where state: 'enabled' }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  def field_options
    %w(from to cc bcc subject body).map { |m| [I18n.t("webmail.options.filter_field.#{m}"), m] }
  end

  def operator_options
    %w(include exclude).map { |m| [I18n.t("webmail.options.filter_operator.#{m}"), m] }
  end

  def state_options
    %w(enabled disabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def action_options
    %w(copy move trash delete).map { |m| [I18n.t("webmail.options.action.#{m}"), m] }
  end

  def mailbox_options
    imap.mailboxes.load.all.map do |box|
      pad = '&nbsp;' * 4 * box.depth
      ["#{pad}#{ERB::Util.html_escape(box.basename)}".html_safe, box.original_name]
    end
  end

  def decode_mailbox
    return nil if mailbox.blank?
    Net::IMAP.decode_utf7(mailbox)
  end

  def search_keys
    keys = []
    conditions.each do |cond|
      next if cond[:field].blank? || cond[:value].blank?
      keys << 'NOT' if cond[:operator] == 'exclude'
      keys << cond[:field].upcase
      keys << cond[:value].dup.force_encoding('ASCII-8BIT')
    end
    keys
  end

  def apply(mailbox, add_search_keys = [])
    imap.select(mailbox)
    uids = imap.conn.uid_sort(%w(REVERSE ARRIVAL), add_search_keys + search_keys, 'UTF-8')
    uids_apply(uids, mailbox)
  end

  private

  def set_conditions
    conditions = self.conditions.map do |data|
      (data[:field].present? && data[:operator].present? && data[:value].present?) ? data : nil
    end
    self.conditions = conditions.compact
  end

  def uids_apply(uids, mailbox)
    count = 0
    return count if uids.blank?

    uids.each_slice(APPLY_PER) do |sliced_uids|
      if action == "copy"
        imap.uids_copy(sliced_uids, self.mailbox)
      elsif action == "move"
        imap.examine(mailbox)
        imap.uids_move(sliced_uids, self.mailbox)
      elsif action == "trash"
        imap.uids_move_trash(sliced_uids)
      elsif action == "delete"
        imap.uids_delete(sliced_uids)
      end

      count += imap.last_response_size
    end

    count
  end
end
