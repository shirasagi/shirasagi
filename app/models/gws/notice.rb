class Gws::Notice
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  #include SS::Addon::Body
  include SS::Addon::Markdown
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :severity, type: String

  permit_params :name, :severity

  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> {
    order_by released: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def severity_options
    [
      [I18n.t('gws.options.severity.high'), 'high'],
    ]
  end
end
