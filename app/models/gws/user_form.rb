class Gws::UserForm
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name 'gws_user_forms', :edit

  field :state, type: String, default: 'closed'
  field :memo, type: String
  has_many :columns, class_name: 'Gws::Column::Base', dependent: :destroy, inverse_of: :form, as: :form

  permit_params :state, :memo

  index({ site_id: 1 }, { unique: true })

  validates :site_id, presence: true, uniqueness: true
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }

  delegate :build_column_values, to: :columns

  class << self
    def find_for_site(site)
      site(site).order_by(id: 1, created: 1).first
    end
  end

  def reference_name
    self.class.model_name.human
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("gws.options.user_form_state.#{m}"), m] }
  end

  def state_public?
    state == 'public'
  end

  def state_closed?
    !state_public?
  end
end
