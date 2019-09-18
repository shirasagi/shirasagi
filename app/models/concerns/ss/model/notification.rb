module SS::Model::Notification
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission
  include SS::Addon::Notification::Reply

  attr_accessor :cur_group

  included do
    store_in collection: "ss_notifications"

    seqid :id

    belongs_to :group, class_name: "SS::Group"

    embeds_ids :members, class_name: "SS::User"

    field :subject, type: String
    field :text, type: String, default: ''
    field :html, type: String, default: ''
    field :format, type: String
    field :seen, type: Hash, default: {}
    field :deleted, type: Hash, default: {}
    field :state, type: String, default: 'public' # always public
    field :send_date, type: DateTime
    field :url, type: String, default: ''

    validates :member_ids, presence: true
    validates :subject, presence: true

    before_validation :set_group_id, if: ->{ @cur_group }
    before_validation :set_send_date

    default_scope -> { order_by(send_date: -1, updated: -1) }

    scope :undeleted, ->(user) { where(:"deleted.#{user.id}".exists => false) }
    scope :unseen, ->(user) { where(:"seen.#{user.id}".exists => false) }
    scope :member, ->(user) { self.in(member_ids: user.id) }

    alias name subject
  end

  private

  def set_group_id
    self.group_id ||= @cur_group.id
  end

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

  def readable?(user, opts = {})
    # return false if self.group_id != opts[:group].id
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

  def subject_with_group
    return self.subject if self.group.blank?
    return "[#{self.group.name}] #{self.subject}"
  end

  module ClassMethods
    def unseens(user, opts = {})
      criteria.member(user).unseen(user)
    end

    def search(params = {})
      criteria = where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :subject)
      end

      if params[:unseen].present?
        user_id = params[:unseen].to_s.gsub(/\D/, '')
        criteria = criteria.where("seen.#{user_id}" => { '$exists' => false })
      end

      criteria
    end
  end
end
