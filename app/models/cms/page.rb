class Cms::Page
  include Cms::Model::Page
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Gravatar::Addon::Gravatar
  include Cms::Addon::Body
  include Cms::Addon::BodyPart
  include Cms::Addon::File
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Date
  include Map::Addon::Page
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Multilingual::Addon::Page

  index({ site_id: 1, filename: 1 }, { unique: true })

  class << self
    def routes
      pages = ::Mongoid.models.select { |model| model.ancestors.include?(Cms::Model::Page) }
      routes = pages.map { |model| model.name.underscore }.sort.uniq
      routes.map do |route|
        mod = route.sub(/\/.*/, '')
        { route: route, module: mod, module_name: I18n.t("modules.#{mod}"), name: I18n.t("mongoid.models.#{route}") }
      end
    end
  end
end
