class Gws::Notice::Post
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Link
  include Gws::Addon::Notice::Category
  include Gws::Addon::Notice::CommentSetting
  include Gws::Addon::Notice::Notification
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

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
      all.search_keyword(params).search_group(params).search_category(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :html)
    end

    def search_group(params)
      return all if params.blank? || params[:group].blank?

      group = params[:group]
      return all if group.blank? || !group.active?

      group_ids = [ group.id ] + group.descendants.active.pluck(:id)

      all.where('$and' =>[
        { '$or' => [
          { :readable_setting_range.exists => false },
          { readable_setting_range: 'select' }
        ] },
        :readable_group_ids.in => group_ids
      ])
    end

    def search_category(params)
      return all if params.blank? || params[:category].blank?
      all.where(category_ids: params[:category].to_i)
    end
  end

  def severity_options
    [
      [I18n.t('gws.options.severity.high'), 'high'],
    ]
  end
end
