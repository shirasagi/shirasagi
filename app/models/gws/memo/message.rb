class Gws::Memo::Message
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::Member
  include Webmail::Addon::MailBody
  include Gws::Addon::File
  include Gws::Addon::Memo::Comments
  include Gws::Addon::Reminder
  alias reminder_user_ids member_ids

  attr_accessor :signature, :attachments, :field, :cur_site, :cur_user
  attr_accessor :in_request_mdn, :in_request_dsn, :state

  field :subject, type: String
  alias name subject

  field :text, type: String, default: ''
  field :html, type: String
  field :format, type: String
  field :size, type: Integer, default: 0
  field :seen, type: Hash, default: {}
  field :star, type: Hash, default: {}
  field :filtered, type: Hash, default: {}
  field :from, type: Hash, default: {}
  field :to, type: Hash, default: {}
  field :send_date, type: DateTime

  permit_params :subject, :text, :html, :format

  default_scope -> { order_by([[:send_date, -1], [:updated, -1]]) }

  before_validation :set_to, :set_size

  validate :validate_attached_file_size
  validate :validate_message

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MemoMessageJob.callback

  after_save :save_reminders, if: ->{ !draft? }

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

  scope :folder, ->(folder) {
    where("#{folder.direction}.#{folder.user_id}" => folder.folder_path)
  }

  scope :unseen, ->(user_id) {
    where("seen.#{user_id}" => { '$exists' => false })
  }

  scope :search_replay, ->(replay_id) {
    where("$and" => [{ "_id" => replay_id }])
  }

  scope :unfiltered, ->(user) {
    where(:"filtered.#{user.id}".exists => false)
  }

  private

  def set_to
    member_ids.map(&:to_s).each do |id|
      next unless self.to[id.to_s].blank?
      self.to[id.to_s] = draft? ? nil : 'INBOX'
    end
  end

  def set_size
    self.size = self.files.pluck(:size).inject(:+)
  end

  public

  def display_subject
    subject.presence || 'No title'
  end

  def display_send_date
    send_date ? send_date.strftime('%Y/%m/%d %H:%M') : I18n.t('gws/memo/folder.inbox_draft')
  end

  def attachments?
    files.present?
  end

  def state_changed?
    false
  end

  def display_to
    members.map(&:long_name)
  end

  def unseen?(user=nil)
    return false if user.nil?
    seen.exclude?(user.id.to_s)
  end

  def star?(user=:nil)
    return false if user == :nil
    star.include?(user.id.to_s)
  end

  def display_size
    result = 1024

    if self.size && (self.size > result)
      result = self.size
    end

    ActiveSupport::NumberHelper.number_to_human_size(result, precision: 0)
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
    args = opts.merge(id: self.id)
    if action == :read
      return self.class.allow(action, user, args).exists?
    end
    return super(action, user, args) unless self.user
    return super(action, user, args) && (self.user.id == user.id)
  end

  def new_memo
    if sign = Gws::Memo::Signature.default_sign(@cur_user)
      self.text = "\n\n#{sign}"
      self.html = "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />')
    end
  end

  def html?
    format == 'html'
  end

  def validate_attached_file_size
    return if site.memo_filesize_limit.blank?
    return if site.memo_filesize_limit <= 0

    limit = site.memo_filesize_limit * 1024 * 1024
    size = files.compact.map(&:size).sum

    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end

  def validate_message
    if self.text.blank? && self.html.blank?
      errors.add(:base, :input_message)
    end
  end

  def reminder_date
    return if site.memo_reminder == 0
    result = Time.zone.now.beginning_of_day + (site.memo_reminder - 1).day
    result.end_of_day
  end

  class << self
    def allow(action, user, opts = {})
      folder = opts[:folder]
      direction = %w(INBOX.Sent INBOX.Draft).include?(folder) ? 'from' : 'to'
      result = where("#{direction}.#{user.id}" => folder)

      if opts[:id]
        result = result.where('_id' => opts[:id])
      end

      result
    end

    def unseens(user, site)
      self.site(site).where('$and' => [
        { "to.#{user.id}".to_sym.exists => true },
        { "seen.#{user.id}".to_sym.exists => false },
        { "$where" => "function(){
  var self = this;
  var result = false;

  Object.keys(this.from).forEach(function(key){
    if (self.from[key] !== 'INBOX.Draft') { result = true; }
  })

  return result;
}"}])
    end
  end

  def h(str)
    ERB::Util.h(str)
  end
end
