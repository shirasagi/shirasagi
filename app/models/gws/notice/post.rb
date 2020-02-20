class Gws::Notice::Post
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Notice::Folder
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Link
  include Gws::Addon::Notice::Category
  include Gws::Addon::Notice::CommentSetting
  include Gws::Addon::Notice::CommentPost
  include Gws::Addon::Notice::Member
  include Gws::Notice::Notification
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Board::BrowsingState

  readable_setting_include_custom_groups

  store_in collection: 'gws_notices'
  set_permission_name 'gws_notices'

  seqid :id
  field :name, type: String
  field :severity, type: String
  field :total_file_size, type: Integer

  permit_params :name, :severity

  validates :name, presence: true, length: { maximum: 80 }
  validate :validate_body_size
  validate :validate_file_size
  before_save :update_body_size
  before_save :update_file_size

  default_scope -> {
    order_by released: -1
  }

  class << self
    def search(params)
      all.search_keyword(params).
        search_severity(params).
        search_folders(params).
        search_category(params).
        search_browsed_state(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :html)
    end

    def search_severity(params)
      return all if params.blank? || params[:severity].blank?
      all.where(severity: params[:severity])
    end

    def search_folders(params)
      return all if params.blank? || params[:folder_ids].blank?

      all.in(folder_id: params[:folder_ids].select(&:numeric?).map(&:to_i))
    end

    def search_category(params)
      return all if params.blank? || params[:category_id].blank?

      all.where(category_ids: params[:category_id].to_i)
    end

    def search_browsed_state(params)
      return all if params.blank? || params[:browsed_state].blank?

      case params[:browsed_state]
      when 'read'
        all.exists("browsed_users_hash.#{params[:user].id}" => 1)
      when 'unread'
        all.exists("browsed_users_hash.#{params[:user].id}" => 0)
      else
        none
      end
    end
  end

  def severity_options
    [
      [I18n.t('gws.options.severity.high'), 'high'],
    ]
  end

  def new_flag?
    (released.presence || release_date.presence || created) > Time.zone.now - site.notice_new_days.day
  end

  private

  def validate_body_size
    return if folder.blank?
    return if text.blank?

    if text.length > folder.notice_individual_body_size_limit
      options = {
        size: text.length.to_s(:human_size),
        limit: folder.notice_individual_body_size_limit.to_s(:human_size)
      }
      errors.add :base, :exceeded_individual_body_size_limit, options
    end

    if text.length + folder.notice_total_body_size > folder.notice_total_body_size_limit
      options = {
        size: (text.length + folder.notice_total_body_size).to_s(:human_size),
        limit: folder.notice_total_body_size_limit.to_s(:human_size)
      }
      errors.add :base, :exceeded_total_body_size_limit, options
    end
  end

  def validate_file_size
    return if folder.blank?

    self.total_file_size = 0
    return if files.blank?

    files.each do |file|
      self.total_file_size += file.size
      next if file.size <= folder.notice_individual_file_size_limit

      options = {
        size: file.size.to_s(:human_size),
        limit: folder.notice_individual_file_size_limit.to_s(:human_size)
      }
      errors.add :base, :exceeded_individual_file_size_limit, options
    end

    if self.total_file_size + folder.notice_total_file_size > folder.notice_total_file_size_limit
      options = {
        size: (self.total_file_size + folder.notice_total_file_size).to_s(:human_size),
        limit: folder.notice_total_file_size_limit.to_s(:human_size)
      }
      errors.add :base, :exceeded_total_file_size_limit, options
    end
  end

  def update_body_size
    return if folder.blank?

    folder_was.inc(notice_total_body_size: - text_was.length) if folder_was && text_was
    folder.inc(notice_total_body_size: text.length) if text
  end

  def update_file_size
    return if folder.blank?

    folder_was.inc(notice_total_file_size: - total_file_size_was) if folder_was && total_file_size_was
    folder.inc(notice_total_file_size: total_file_size) if total_file_size
  end
end
