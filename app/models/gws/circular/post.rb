class Gws::Circular::Post
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Circular::See
  include Gws::Circular::Sort
  include Gws::Addon::Reminder
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Circular::Category
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

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

  scope :and_public, -> {
    where(state: 'public')
  }

  scope :without_deleted, ->(date = Time.zone.now) {
    where("$and" => [
        { "$or" => [{ deleted: nil }, { :deleted.gt => date }] }
    ])
  }

  scope :only_deleted, -> {
    where(:deleted.exists => true)
  }

  class << self
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

  def public?
    state == 'public'
  end

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

  def article_state_options
    %w(both unseen).map do |v|
      [ I18n.t("gws/circular.options.article_state.#{v}"), v ]
    end
  end

  private

  def validate_attached_file_size
    return if site.circular_filesize_limit.blank?
    return if site.circular_filesize_limit <= 0

    limit = site.circular_filesize_limit * 1024 * 1024
    size = files.compact.map(&:size).sum

    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end
end
