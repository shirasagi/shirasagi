class Gws::Elasticsearch::Setting::Discussion
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Discussion::Topic

  def allowed?(method)
    model.allowed?(:edit, cur_user, site: cur_site)
  end

  def menu_label
    cur_site.menu_discussion_label.presence || I18n.t('modules.gws/discussion')
  end

  def search_types
    return [] unless cur_site.menu_discussion_visible?
    return [] unless Gws.module_usable?(:discussion, cur_site, cur_user)

    super
  end
end
