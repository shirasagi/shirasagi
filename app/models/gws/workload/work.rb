class Gws::Workload::Work
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Workload::Yearly
  #include Gws::Addon::Reminder
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # index({ site_id: 1, post_id: 1, deleted: 1 })
  # index({ due_date: 1, site_id: 1, post_id: 1, deleted: 1 })
  # index({ updated: 1, site_id: 1, post_id: 1, deleted: 1 })
  # index({ created: 1, site_id: 1, post_id: 1, deleted: 1 })

  member_include_custom_groups
  permission_include_custom_groups

  seqid :id

  field :name, type: String
  field :due_date, type: DateTime
  field :state, type: String, default: 'public'

  belongs_to :category, class_name: "Gws::Workload::Category"
  belongs_to :client, class_name: "Gws::Workload::Client"
  belongs_to :cycle, class_name: "Gws::Workload::Cycle"
  belongs_to :load, class_name: "Gws::Workload::Load"

  permit_params :name, :due_date, :deleted
  permit_params :category_id, :client_id, :cycle_id, :load_id

  validates :name, presence: true
  validates :due_date, presence: true
  validate :validate_attached_file_size

  alias reminder_date due_date
  alias reminder_user_ids member_ids

  # has_many :comments, class_name: 'Gws::Circular::Comment', dependent: :destroy, inverse_of: :post, order: { created: 1 }

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::CircularPostJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::CircularPostJob.callback

  scope :topic, -> { exists post_id: false }

  scope :and_public, -> {
    where(state: 'public')
  }

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      all.reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      all.reorder(updated: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('due_date')
      all.reorder(due_date: key.end_with?('_asc') ? 1 : -1)
    else
      all
    end
  }

  def category_options
    Gws::Workload::Category.site(site || @cur_site).map { |c| [c.name, c.id] }
  end

  def client_options
    Gws::Workload::Client.site(site || @cur_site).map { |c| [c.name, c.id] }
  end

  def cycle_options
    Gws::Workload::Cycle.site(site || @cur_site).map { |c| [c.name, c.id] }
  end

  def load_options
    Gws::Workload::Load.site(site || @cur_site).map { |c| [c.name, c.id] }
  end

  def sort_options
    %w(due_date_desc due_date_asc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/workload.options.sort.#{k}"), k]
    end
  end

  class << self
    def search(params)
      criteria = all
      criteria = criteria.search_keyword(params)
      criteria = criteria.search_category_id(params)
      criteria = criteria.search_client_id(params)
      criteria = criteria.search_state(params)
      criteria = criteria.search_year(params)
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_category_id(params)
      return all if params.blank? || params[:category_id].blank?

      all.where(category_id: params[:category_id])
    end

    def search_client_id(params)
      return all if params.blank? || params[:client_id].blank?

      all.where(client_id: params[:client_id])
    end

    def search_state(params)
      return all if params.blank? || params[:state].blank?

      all.where(state: params[:state])
    end

    def to_csv
      CSV.generate do |data|
        data << I18n.t('gws/workload.csv')
        each do |item|
          data << [
            item.id,
            item.name,
            item.year,
            item.category.try(:name),
            item.client.try(:name),
            item.cycle.try(:name),
            item.load.try(:name),
          ]
        end
      end
    end
  end

  # def reminder_url
  #   name = reference_model.tr('/', '_') + '_path'
  #   [name, category: '-', id: id, site: site_id]
  # end

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

  # def custom_group_member?(user)
  #   custom_groups.where(member_ids: user.id).exists?
  # end

  # def user?(user)
  #   self.user.id == user.id
  # end

  def state_options
    %w(public draft).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  private

  def validate_attached_file_size
    return if site.circular_filesize_limit.blank?
    return if site.circular_filesize_limit <= 0

    limit = site.circular_filesize_limit_in_bytes
    size = files.compact.sum(&:size)
    if size > limit
      errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
    end
  end
end
