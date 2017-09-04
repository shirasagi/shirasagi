class Gws::Elasticsearch::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view 'gws/elasticsearch/settings/navi'

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.gws/elasticsearch/group_setting'), gws_elasticsearch_setting_path]
  end
end
