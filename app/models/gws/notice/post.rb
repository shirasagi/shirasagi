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
  include Gws::Addon::Notice::Notification
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Board::BrowsingState

  store_in collection: 'gws_notices'
  set_permission_name 'gws_notices'

  seqid :id
  field :name, type: String
  field :severity, type: String

  permit_params :name, :severity

  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> {
    order_by released: -1
  }

  class << self
    def search(params)
      all.search_keyword(params).search_folders(params).search_category(params).search_browsed_state(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :html)
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
end
