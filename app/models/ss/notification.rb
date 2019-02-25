class SS::Notification
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include SS::UserPermission
  include SS::Addon::Notification::Body
  include SS::Addon::Notification::Reply
  include SS::Addon::File
  #include Gws::SitePermission

  #set_permission_name 'private_gws_memo_notices', :edit

  seqid :id

  embeds_ids :members, class_name: "SS::User"

  field :subject, type: String
  field :text, type: String, default: ''
  field :html, type: String, default: ''
  field :format, type: String
  field :seen, type: Hash, default: {}
  field :deleted, type: Hash, default: {}
  field :state, type: String, default: 'public' # always public
  field :send_date, type: DateTime
  field :export, type: Boolean, default: false
  field :url, type: String, default: ''

  validates :member_ids, presence: true
  validates :subject, presence: true

  before_validation :set_send_date

  default_scope -> { order_by(send_date: -1, updated: -1) }

  scope :undeleted, ->(user) { where(:"deleted.#{user.id}".exists => false) }
  scope :unseen, ->(user) { where(:"seen.#{user.id}".exists => false) }
  scope :member, ->(user) { self.in(member_ids: user.id) }

  alias name subject

  private

  def set_send_date
    self.send_date ||= Time.zone.now if state == "public"
  end

  public

  def set_seen(user)
    self.seen[user.id.to_s] = Time.zone.now
    self
  end

  def display_send_date
    send_date ? send_date.strftime('%Y/%m/%d %H:%M') : ''
  end

  def member?(user)
    member_ids.include?(user.id)
  end

  def unseen?(user)
    seen[user.id.to_s].nil?
  end

  def deleted?(user)
    deleted[user.id.to_s].present?
  end

  def attachments?
    files.present?
  end

  def readable?(user, site)
    if site.present?
      return false if self.site_id != site.id
    end
    return false if deleted?(user)
    member?(user)
  end

  def destroy_from_member(user)
    self.member_ids = member_ids - [user.id]
    self.deleted[user.id.to_s] = Time.zone.now

    if member_ids.blank?
      destroy
    else
      update
    end
  end

  class << self
    def unseens(user, site)
      if site.present?
        criteria.site(site).member(user).unseen(user)
      else
        criteria.member(user).unseen(user)
      end
    end

    def search(params = {})
      criteria = where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :subject)
      end

      if params[:unseen].present?
        user_id = params[:unseen]
        criteria = criteria.where("seen.#{user_id}" => { '$exists' => false })
      end

      criteria
    end
  end
end
