class Gws::Circular::Post
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Circular::See
  include Gws::Circular::Sort
  # include Gws::Circular::Commentable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Circular::Category
  include Gws::Addon::Reminder

  seqid :id

  field :name, type: String
  field :due_date, type: DateTime
  field :deleted, type: DateTime
  field :state, type: String, default: 'public'

  permit_params :name, :due_date, :deleted

  validates :name, presence: true
  validates :due_date, presence: true
  validates :deleted, datetime: true
  validate :validate_attached_file_size

  alias reminder_date due_date
  alias reminder_user_ids member_ids

  has_many :comments, class_name: 'Gws::Circular::Comment', dependent: :destroy, inverse_of: :post, order: { created: 1 }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::CircularPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::CircularPostJob.callback

  scope :topic, ->{ exists post_id: false }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if sort_num = params[:sort].to_i
      criteria = criteria.order_by(new.sort_hash(sort_num))
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    if params[:category_id].present?
      criteria = criteria.in(category_ids: params[:category_id])
    end

    criteria
  }

  scope :and_posts, ->(userid, key) {
    if key.start_with?('both')
      where("$and" => [ { state: { "$not" => /^closed$/ } } ] )
    elsif key.start_with?('unseen')
      where("$and" => [ { "seen.#{userid}".to_sym => { "$exists" => false } },
                        { state: { "$not" => /^closed$/ } }
                      ] )
    end
  }

  scope :and_admins, ->(user) {
    where("$and" => [
        { "$or" => [{ :user_ids.in => [user.id] }, { :group_ids.in => user.group_ids }] }
    ])
  }

  scope :without_deleted, ->(date = Time.zone.now) {
    where("$and" => [
        { "$or" => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :deleted, -> {
    where(:deleted.exists => true)
  }

  def active?
    deleted.blank? || deleted > Time.zone.now
  end

  def active
    update_attributes(deleted: nil)
  end

  def disable
    update_attributes(deleted: Time.zone.now) if active?
  end

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def user?(user)
    self.user.id == user.id
  end

  def readable?(user, opts = {})
    readable_group_ids.blank? && readable_member_ids.blank? && readable_custom_group_ids.blank? ||
      readable_group_ids.any? { |m| user.group_ids.include?(m) } ||
      readable_member_ids.include?(user.id) ||
      readable_custom_groups.any? { |m| m.member_ids.include?(user.id) }
  end

  def allowed?(action, user, opts = {})
    return true if super(action, user, opts)
    return true if action =~ /read/ && readable?(user)
    return user?(user) || member?(user) || custom_group_member?(user) if action =~ /read/
    false
  end

  def state
    'public'
  end

  def state_changed?
    false
  end

  def article_state_options
    [
      [I18n.t('gws/circular.options.article_state.both'), 'both'],
      [I18n.t('gws/circular.options.article_state.unseen'), 'unseen']
    ]
  end

  def validate_attached_file_size
    return if site.circular_filesize_limit.blank?
    return if site.circular_filesize_limit <= 0

    limit = site.circular_filesize_limit * 1024 * 1024
    size = files.compact.map(&:size).sum

    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end

  class << self
    def owner(action, user, opts = {})
      where(owner_condition(action, user, opts))
    end

    def owner_condition(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
      action = permission_action || action

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { permission_level: { "$lte" => level } },
        ] }
      elsif level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { :group_ids.in => user.group_ids, "$or" => [{ permission_level: { "$lte" => level } }] }
        ] }
      else
        { user_ids: user.id }
      end
    end

    def allow_condition(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector['site_id']
      action = permission_action || action
      conds = [
        { user_ids: user.id },
        { member_ids: user.id },
        { readable_member_ids: user.id },
        { :readable_group_ids.in => user.group_ids }
      ]

      if readable_setting_included_custom_groups?
        conds << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        conds << { permission_level: { '$lte' => level } }
      elsif level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        conds << { :group_ids.in => user.group_ids, '$or' => [{ permission_level: { '$lte' => level } }] }
      end

      { '$or' => conds }
    end

    def to_csv
      CSV.generate do |data|
        data << I18n.t('gws/circular.csv')
        each do |item|
          item.comments.each do |comment|
            data << [
                item.id,
                item.name,
                comment.id,
                item.seen?(comment.user) ? I18n.t('gws/circular.post.seen') : I18n.t('gws/circular.post.unseen') ,
                comment.user.long_name,
                comment.text,
                comment.updated.strftime('%Y/%m/%d %H:%M')
            ]
          end
        end
      end
    end
  end
end
