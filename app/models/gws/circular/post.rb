class Gws::Circular::Post
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Circular::See
  include Gws::Circular::Commentable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Circular::Category

  seqid :id

  field :name, type: String
  field :due_date, type: DateTime
  field :deleted, type: DateTime

  permit_params :name, :due_date, :deleted

  validates :name, presence: true
  validates :due_date, presence: true
  validates :deleted, datetime: true

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::CircularPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::CircularPostJob.callback

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if sort_num = params[:sort].to_i
      criteria = criteria.order_by(new.sort_hash(sort_num))
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end

    criteria
  }

  scope :without_deleted, ->(date = Time.zone.now) {
    where('$and' => [
      { '$or' => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :deleted, -> {
    where(:deleted.exists => true)
  }

  scope :expired, ->(date = Time.zone.now) {
    where('$or' => [
      { :deleted.exists => true , :deleted.lt => date }
    ])
  }

  def active?
    return true unless deleted.present? && deleted < Time.zone.now
    false
  end

  def active
    update_attributes(deleted: nil)
  end

  def disable
    update_attributes(deleted: Time.zone.now) if deleted.blank? || deleted > Time.zone.now
  end

  def sort_items
    [
        { key: :updated, order: -1, name: I18n.t('mongoid.attributes.ss/document.updated')},
        { key: :created, order: -1, name: I18n.t('mongoid.attributes.ss/document.created')}
    ]
  end

  def sort_hash(num=0)
    result = {}
    item = sort_items[num]
    result[item[:key]] = item[:order]
    result
  end

  def sort_options
    sort_items.map.with_index { |item, i| [item[:name], i] }
  end

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def allowed?(action, user, opts = {})
    return true if super(action, user, opts)
    member?(user) || custom_group_member?(user) if action =~ /read/
  end

  def readable_names
    users.map(&:long_name) + readable_member_names + readable_group_names
  end

  class << self
    def allow_condition(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
      action = permission_action || action

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id },
          { permission_level: { "$lte" => level } },
        ] }
      elsif level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id },
          { :group_ids.in => user.group_ids, "$or" => [{ permission_level: { "$lte" => level } }] }
        ] }
      else
        { "$or" => [
          { user_ids: user.id },
          { member_ids: user.id }
        ] }
      end
    end

    def to_csv
      CSV.generate do |data|
        data << I18n.t('gws/circular.csv')
        each do |item|
          item.members.each do |member|
            post = item.comments.find {|c| c.user_id == member.id }
            data << [
                item.id,
                item.name,
                post.try(:id),
                item.seen?(member),
                member.name,
                post.try(:text),
                post.try(:updated)
            ]
          end
        end
      end
    end
  end
end
