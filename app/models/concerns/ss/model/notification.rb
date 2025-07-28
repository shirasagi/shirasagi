module SS::Model::Notification
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission
  include SS::Addon::Notification::Reply
  include SS::UserSettings

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
    field :state, type: String, default: 'public' # always public
    field :send_date, type: DateTime
    field :url, type: String, default: ''

    validates :member_ids, presence: true
    validates :subject, presence: true

    before_validation :set_group_id, if: ->{ @cur_group }
    before_validation :set_send_date

    default_scope -> { order_by(send_date: -1, updated: -1) }

    scope :member, ->(user) { self.in(member_ids: user.id) }

    alias_method :name, :subject
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
    upsert_user_setting(user.id, "seen_at", Time.zone.now.utc)
    self
  end

  def unset_seen(user)
    delete_user_setting(user.id, "seen_at")
    self
  end

  def display_send_date
    send_date ? I18n.l(send_date, format: :picker) : ''
  end

  def member?(user)
    member_ids.include?(user.id)
  end

  def unseen?(user)
    find_user_setting(user.id, "seen_at").blank?
  end

  def deleted?(user)
    find_user_setting(user.id, "deleted").present?
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
    self.member_ids = (member_ids - [user.id]).select(&:present?)
    if member_ids.blank?
      return destroy
    end

    result = save
    upsert_user_setting(user.id, "deleted", Time.zone.now.utc) if result
    result
  end

  def subject_with_group
    return self.subject if self.group.blank?
    "[#{self.group.name}] #{self.subject}"
  end

  module ClassMethods
    def undeleted(user_or_user_id)
      and_user_setting_blank(user_or_user_id, "deleted")
    end

    def unseen(user_or_user_id)
      and_user_setting_blank(user_or_user_id, "seen_at")
    end

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
        criteria = criteria.unseen(user_id)
      end

      criteria
    end
  end
end
