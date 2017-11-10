class Gws::Memo::Message
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::Member
  include Webmail::Addon::MailBody
  include Gws::Addon::File
  include Gws::Addon::Memo::Comments

  attr_accessor :signature, :attachments, :field, :cur_site, :cur_user
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
  field :to, type: Hash, default: {}
  field :send_date, type: DateTime

  permit_params :subject, :text, :html, :format

  default_scope -> { order_by([[:send_date, -1], [:updated, -1]]) }

  before_validation :set_to

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
    members.map(&:long_name)
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
    Gws::Memo::Signature.site(cur_site).allow(:read, cur_user, site: cur_site).map do |c|
      [c.name, c.text]
    end
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
    return true if self.member_ids.include?(user.id)
    false
  end

  def apply_filters(user)
    matched_filter = Gws::Memo::Filter.site(site).
      allow(:read, user, site: site).enabled.detect{ |f| f.match?(self) }

    self.to[user.id.to_s] = matched_filter.path if matched_filter
    self.filtered[user.id.to_s] = Time.zone.now
    self
  end

  def allowed?(action, user, opts = {})
    action = permission_action || action
    return self.class.allow(action, user, opts).exists? if action == :read
    return super(action, user, opts) unless self.user
    return super(action, user, opts) && (self.user.id == user.id)
  end

  private

  def set_to
    (member_ids.map(&:to_s) - to.keys).each { |id| self.to[id.to_s] = draft? ? nil : 'INBOX' }
  end

  class << self
    def allow(action, user, opts = {})
      folder = opts[:folder]
      direction = %w(INBOX.Sent INBOX.Draft).include?(folder) ? 'from' : 'to'
      where("#{direction}.#{user.id}" => folder)
    end
  end
end
