class Gws::Memo::Message
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::FreePermission
  include Webmail::Addon::MailBody
  include Gws::Addon::File

  attr_accessor :signature, :attachments, :field

  field :subject, type: String
  field :text, type: String
  field :html, type: String
  field :format, type: String
  field :size, type: Integer, default: 0
  field :state, type: String, default: 'public'

  field :seen_hash, type: Hash, default: {}
  field :star_hash, type: Hash, default: {}

  field :from, type: Hash, default: {}
  embeds_ids :from_users, class_name: 'Gws::User' # => from_user_ids

  field :to, type: Hash, default: {}
  embeds_ids :to_users, class_name: 'Gws::User' # => to_user_ids

  permit_params :subject, :text, :html, :format, :to_text

  default_scope -> { order_by internal_date: -1 }

  before_validation :set_from_user_ids
  before_validation :set_to_user_ids

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?
    criteria = criteria.keyword_in params[:keyword], :subject, :text, :html if params[:keyword].present?
    criteria
  }

  def to_text=(obj)
    obj.split(';').each do |val|
      addr = val.strip.match(/<(.+?)>$/)[1]
      next unless user = Gws::User.where(email: addr).first
      self.to[user.id.to_s] = 'INBOX'
    end
  end

  def to_text
    to_users.map(&:email_address).join('; ')
  end

  def sender
    from_users.map(&:long_name)
  end
  alias_method :display_sender, :sender

  def display_subject
    subject.presence || 'No title'
  end

  def attachments?
    files.present?
  end

  def display_to
    to_users.map(&:long_name)
  end

  def unseen?(user=:nil)
    return false if user == :nil
    seen_hash.exclude?(user.id.to_s)
  end

  def star?(user=:nil)
    return false if user == :nil
    star_hash.include?(user.id.to_s)
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
    self.seen_hash[user.id.to_s] = Time.zone.now
    self
  end

  def unset_seen(user)
    self.seen_hash.delete(user.id.to_s)
    self
  end

  def set_star(user)
    self.star_hash[user.id.to_s] = Time.zone.now
    self
  end

  def unset_star(user)
    self.star_hash.delete(user.id.to_s)
    self
  end

  def toggle_star(user)
    star?(user) ? unset_star(user) : set_star(user)
  end

  private

  def set_from_user_ids
    from.keys.each {|id_s| self.from_user_ids = self.from_user_ids << id_s.to_i }
  end

  def set_to_user_ids
    to.keys.each {|id_s| self.to_user_ids = self.to_user_ids << id_s.to_i }
  end

end
