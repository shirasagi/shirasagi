module Opendata::Resource::HistoryArchiveFileModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Model::File
  include Cms::Reference::Site
  include Cms::SitePermission
  include Cms::Lgwan::File

  included do
    set_permission_name "opendata_histories", :read

    default_scope ->{ where(model: model_name.i18n_key.to_s) }
  end

  def previewable?(site: nil, user: nil, member: nil)
    return false if user.blank?
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id

    user.cms_user.cms_role_permit_any?(site, :read_opendata_histories)
  end
end
