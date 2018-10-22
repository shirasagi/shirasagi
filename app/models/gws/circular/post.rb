class Gws::Circular::Post
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Circular::See
  include Gws::Circular::Sort
  #include Gws::Addon::Reminder
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Circular::Category
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  member_include_custom_groups
  permission_include_custom_groups

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

  after_save :send_notification

  alias reminder_date due_date
  alias reminder_user_ids member_ids

  has_many :comments, class_name: 'Gws::Circular::Comment', dependent: :destroy, inverse_of: :post, order: { created: 1 }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::CircularPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::CircularPostJob.callback

  scope :topic, ->{ exists post_id: false }

  scope :and_public, -> {
    where(state: 'public')
  }

  class << self
    def search(params)
      criteria = all
      criteria = criteria.search_keyword(params)
      criteria = criteria.search_category_id(params)
      criteria = criteria.search_state(params)
      criteria = criteria.search_article_state(params)
      criteria = criteria.order_by_sort(params)
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_category_id(params)
      return all if params.blank? || params[:category_id].blank?
      all.in(category_ids: params[:category_id])
    end

    def search_state(params)
      return all if params.blank? || params[:state].blank?
      all.where(state: params[:state])
    end

    def search_article_state(params)
      return all if params.blank? || params[:article_state].blank?
      return all if params[:article_state] == 'both'
      case params[:article_state]
      when 'seen'
        exists("seen.#{params[:user].id}" => true)
      when 'unseen'
        exists("seen.#{params[:user].id}" => false)
      end
    end

    def order_by_sort(params)
      return all if params.blank? || params[:sort].blank?
      all.reorder(new.sort_hash(params[:sort].to_i))
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
              item.seen?(comment.user) ? I18n.t('gws/circular.post.seen') : I18n.t('gws/circular.post.unseen'),
              comment.user.long_name,
              comment.text,
              comment.updated.strftime('%Y/%m/%d %H:%M')
            ]
          end
        end
      end
    end
  end

  def reminder_url
    name = reference_model.tr('/', '_') + '_path'
    [name, category: '-', id: id, site: site_id]
  end

  def draft?
    !public?
  end

  def public?
    state == 'public'
  end

  def active?
    !deleted?
  end

  def deleted?
    deleted.present? && deleted <= Time.zone.now
  end

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def user?(user)
    self.user.id == user.id
  end

  def state_options
    %w(public draft).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
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

  def send_notification
    return unless @cur_site.notify_model?(self)

    added_member_ids = removed_member_ids = []

    if state == 'public'
      cur_member_ids = sorted_overall_members.pluck(:id)
      prev_member_ids = sorted_overall_members_was.pluck(:id)

      if state_was == 'draft'
        # just published
        added_member_ids = cur_member_ids
        removed_member_ids = []
      else
        added_member_ids = cur_member_ids - prev_member_ids
        removed_member_ids = prev_member_ids - cur_member_ids
      end
    end

    if state == 'draft' && state_was == 'public'
      # just depublished
      cur_member_ids = sorted_overall_members.pluck(:id)
      prev_member_ids = sorted_overall_members_was.pluck(:id)

      added_member_ids = []
      removed_member_ids = (cur_member_ids + prev_member_ids).uniq
    end

    cur_user_id = @cur_user.try(:id) || user.id
    added_member_ids   -= [cur_user_id]
    removed_member_ids -= [cur_user_id]
    added_member_ids.select!{|user_id| Gws::User.find(user_id).use_notice?(self)}
    removed_member_ids.select!{|user_id| Gws::User.find(user_id).use_notice?(self)}

    return if added_member_ids.blank? && removed_member_ids.blank?
    create_memo_notice(added_member_ids, removed_member_ids)
  end

  def create_memo_notice(added_member_ids, removed_member_ids)
    url_helper = Rails.application.routes.url_helpers
    if added_member_ids.present?
      message = Gws::Memo::Notice.new
      message.cur_site = site
      message.cur_user = @cur_user || user
      message.member_ids = added_member_ids
      message.send_date = Time.zone.now
      message.subject = I18n.t("gws_notification.gws/circular/post.subject", name: name)
      message.format = 'text'
      message.text = url_helper.gws_circular_post_path(id: id, site: cur_site.id, category: '-', mode: '-')
      message.save!

      to_users = added_member_ids.map{|user_id| Gws::User.find(user_id)}
      Gws::Memo::Mailer.notice_mail(message, to_users, self).try(:deliver_now)
    end

    if removed_member_ids.present?
      message = Gws::Memo::Notice.new
      message.cur_site = site
      message.cur_user = @cur_user || user
      message.member_ids = removed_member_ids
      message.send_date = Time.zone.now
      message.subject = I18n.t("gws_notification.gws/circular/post/remove.subject", name: name)
      message.format = 'text'
      message.text = I18n.t("gws_notification.gws/circular/post/remove.text", name: name)
      message.save!

      to_users = removed_member_ids.map{|user_id| Gws::User.find(user_id)}
      Gws::Memo::Mailer.notice_mail(message, to_users, self).try(:deliver_now)
    end
  end
end
