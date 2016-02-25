class Gws::Link
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include SS::Addon::Body
  #include SS::Addon::Markdown
  include Cms::Addon::Release
  #include Cms::Addon::ReleasePlan
  include Gws::Addon::GroupPermission

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :released, type: DateTime

  permit_params :state, :name, :released

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  after_validation :set_released, if: -> { state == "public" }

  default_scope -> {
    order_by released: -1
  }
  scope :and_public, -> {
    where state: "public"
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def state_options
    [
      [I18n.t('views.options.state.public'), 'public'],
      [I18n.t('views.options.state.closed'), 'closed'],
    ]
  end

  private
    def set_released
      self.released ||= Time.zone.now
    end
end
