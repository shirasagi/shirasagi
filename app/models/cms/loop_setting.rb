class Cms::LoopSetting
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::Addon::Html

  set_permission_name "cms_loop_settings", :edit

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  field :state, type: String, default: "public"
  field :html_format, type: String
  permit_params :name, :description, :order, :html_format
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }
  validates :html_format, inclusion: { in: %w(shirasagi liquid), allow_blank: true }

  default_scope -> { order_by(order: 1, name: 1) }

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
      use_html_format.map do |v|
        [ I18n.t("cms.options.loop_format.#{v}"), v ]
      end
    end

    def html_format_shirasagi?
      html_format == "shirasagi"
    end

    def html_format_liquid?
      html_format == "liquid"
    end

    def use_html_format
      %w(shirasagi liquid)
    end
  end

  def html_format_changed?
    changed_attributes.key?("html_format")
  end
end
