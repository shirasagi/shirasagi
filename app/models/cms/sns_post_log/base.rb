class Cms::SnsPostLog::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: 'cms_sns_post_logs'

  set_permission_name "cms_tools", :use

  field :name, type: String
  field :action, type: String, default: "unknown"
  field :state, type: String, default: "error"
  field :error, type: String

  field :source_name, type: String
  belongs_to :source, class_name: "Object", polymorphic: true

  before_validation :set_name

  default_scope -> { order_by(created: -1) }

  index({ created: -1 })

  def type
    "base"
  end

  def state_options
    I18n.t("cms.options.sns_post_log_state").map { |k, v| [v, k] }
  end

  def type_options
    I18n.t("cms.options.sns_post_log_type").map { |k, v| [v, k] }
  end

  def page
    return if @_page == false
    return @_page if @_page
    @_page = soruce.include?(Cms::Model::Page) ? source.page.becomes_with_route : false
  end

  private

  def set_name
    self.name ||= "[#{label(:state)}] #{label(:type)} #{created.strftime("%Y/%m/%d %H:%M")}"
  end

  class << self
    def create_with(item)
      log = self.new
      log.site = item.site
      log.source_name = item.name
      log.source = item
      yield(log)
      log.save
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
