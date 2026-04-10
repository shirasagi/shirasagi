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
  field :html_format, type: String, default: "shirasagi"
  field :loop_html_setting_type, type: String, default: "template"
  field :state, type: String, default: "public"
  permit_params :name, :description, :order, :html_format, :loop_html_setting_type, :state, :html
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }
  validates :html_format, inclusion: { in: %w(shirasagi liquid), allow_blank: true }
  validates :loop_html_setting_type, inclusion: { in: %w(template snippet), allow_blank: true }
  validates :state, inclusion: { in: %w(public closed), allow_blank: true }
  validates :html, liquid_format: true, if: ->{ html_format_liquid? }

  default_scope -> { order_by(order: 1, name: 1) }
  scope :public_state, -> { where(:state.in => [nil, 'public']) }
  scope :liquid, -> { public_state.where(html_format: 'liquid') }
  scope :shirasagi, -> { public_state.where(:html_format.in => [nil, 'shirasagi']) }
  scope :template_type, -> { where(:loop_html_setting_type.in => [nil, 'template']) }
  scope :snippet_type, -> { where(loop_html_setting_type: 'snippet') }

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
      if params[:html_format].present?
        case params[:html_format]
        when 'liquid'
          criteria = criteria.where(html_format: 'liquid')
        when 'shirasagi'
          criteria = criteria.where(:html_format.in => [nil, 'shirasagi'])
        end
      end
      if params[:loop_html_setting_type].present?
        case params[:loop_html_setting_type]
        when 'template'
          criteria = criteria.where(:loop_html_setting_type.in => [nil, 'template'])
        when 'snippet'
          criteria = criteria.where(loop_html_setting_type: 'snippet')
        end
      end
      criteria
    end
  end

  def html_format_shirasagi?
    !html_format_liquid?
  end

  def html_format_liquid?
    html_format == "liquid"
  end

  def state_options
    %w(public closed).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def html_format_options
    %w(shirasagi liquid).map do |v|
      [I18n.t("cms.options.loop_format.#{v}"), v]
    end
  end

  def loop_html_setting_type_options
    %w(template snippet).map do |v|
      [I18n.t("cms.options.loop_html_setting_type.#{v}"), v]
    end
  end
end
