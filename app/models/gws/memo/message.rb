class Gws::Memo::Message
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Webmail::Addon::MailBody
  include Gws::Addon::File
  include Gws::Addon::Memo::Comments
  include Gws::Addon::GroupPermission

  attr_accessor :signature, :attachments, :field
  attr_accessor :in_request_mdn, :in_request_dsn

  field :subject, type: String
  alias name subject

  field :text, type: String
  field :html, type: String
  field :format, type: String
  field :size, type: Integer, default: 0
  field :state, type: String, default: 'public'

  field :seen, type: Hash, default: {}
  field :star, type: Hash, default: {}
  field :filtered, type: Hash, default: {}

  field :from, type: Hash, default: {}
  embeds_ids :from_users, class_name: 'Gws::User' # => from_user_ids

  field :to, type: Hash, default: {}
  embeds_ids :to_users, class_name: 'Gws::User' # => to_user_ids

  field :send_date, type: DateTime

  permit_params :subject, :text, :html, :format, :to_text

  default_scope -> { order_by([[:send_date, -1], [:updated, -1]]) }

  before_validation :set_from_user_ids
  before_validation :set_to_user_ids

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:subject].present?
      criteria = criteria.keyword_in params[:subject], :subject
    end

    params.values_at(:text, :html).reject(&:blank?).each do |value|
      criteria = criteria.keyword_in value, :text, :html
    end

    criteria
  }

  scope :unfiltered, ->(user) {
    where(:"filtered.#{user.id}".exists => false)
  }

  def to_text=(obj)
    obj.split(';').each do |val|
      addr = val.strip.match(/<(.+?)>$/)[1]
      next unless user = Gws::User.where(email: addr).first
      self.to[user.id.to_s] = draft? ? nil : 'INBOX'
    end
  end

  def to_text
    to_users.map(&:email_address).join('; ')
  end

  def display_sender
    from_users.map(&:long_name)
  end

  def display_subject
    subject.presence || 'No title'
  end

  def display_send_date
    send_date ? send_date.strftime('%Y/%m/%d %H:%M') : I18n.t('gws/memo/folder.inbox_draft')
  end

  def attachments?
    files.present?
  end

  def display_to
    to_users.map(&:long_name)
  end

  def unseen?(user=:nil)
    return false if user == :nil
    seen.exclude?(user.id.to_s)
  end

  def star?(user=:nil)
    return false if user == :nil
    star.include?(user.id.to_s)
  end

  def display_size
    size = (self.size < 1024) ? 1024 : self.size
    ActiveSupport::NumberHelper.number_to_human_size(size, precision: 0)
  end

  def format_options
    %w(text html).map { |c| [c.upcase, c] }
  end

  def signature_options
    [nil, nil]
  end

  def set_seen(user)
    self.seen[user.id.to_s] = Time.zone.now
    self
  end

  def unset_seen(user)
    self.seen.delete(user.id.to_s)
    self
  end

  def set_star(user)
    self.star[user.id.to_s] = Time.zone.now
    self
  end

  def unset_star(user)
    self.star.delete(user.id.to_s)
    self
  end

  def toggle_star(user)
    star?(user) ? unset_star(user) : set_star(user)
  end

  def move(user, path)
    self.to[user.id.to_s] = path
    self
  end

  def draft?
    from.values.include?('INBOX.Draft')
  end

  def owned?(user)
    return true if (self.group_ids & user.group_ids).present?
    return true if user_ids.to_a.include?(user.id)
    return true if custom_groups.any? { |m| m.member_ids.include?(user.id) }
    return true if self.to_user_ids.include?(user.id)
    false
  end

  def apply_filters(user)
    matched_filter = Gws::Memo::Filter.site(site).
      allow(:read, user, site: site).enabled.detect{ |f| f.match?(self) }

    self.to[user.id.to_s] = matched_filter.path if matched_filter
    self.filtered[user.id.to_s] = Time.zone.now
    self
  end

  private

  def set_from_user_ids
    from.keys.each { |id_s| self.from_user_ids = self.from_user_ids << id_s.to_i }
  end

  def set_to_user_ids
    to.keys.each { |id_s| self.to_user_ids = self.to_user_ids << id_s.to_i }
  end

  class << self
    def allow_condition(action, user, opts = {})
      folder = opts[:folder]
      direction = %w(INBOX.Sent INBOX.Draft).include?(folder) ? 'from' : 'to'
      { "#{direction}.#{user.id}" => folder }
    end
  end
end
