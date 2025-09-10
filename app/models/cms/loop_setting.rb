class Cms::LoopSetting
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_loop_settings", :edit

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  field :state, type: String, default: "public"
  field :html_format, type: String
  field :html, type: String
  permit_params :name, :description, :order, :html_format, :html
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }
  validates :html_format, presence: true, inclusion: { in: %w(shirasagi liquid) }

  default_scope -> { order_by(order: 1, name: 1) }
  scope :public_state, -> { where(state: 'public') }
  scope :liquid, -> { public_state.where(html_format: 'liquid') }
  scope :shirasagi, -> { public_state.where(html_format: 'shirasagi') }

  before_validation do
    self.html_format = html_format.to_s.downcase.presence || 'shirasagi'
  end
  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :html
      end
      criteria
    end

    def options_for_state
      [
        [I18n.t('ss.options.state.public'), 'public'],
        [I18n.t('ss.options.state.closed'), 'closed']
      ]
    end

    def html_format_options
      %w(SHIRASAGI Liquid).map do |v|
        [ v, v.downcase ]
      end
    end
  end

  def html_format_shirasagi?
    !html_format_liquid?
  end

  def html_format_liquid?
    html_format == "liquid"
  end
end
