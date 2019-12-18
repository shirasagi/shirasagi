module Opendata::Resource::HistoryArchiveFileModel
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Model::File
  include Cms::Reference::Site
  include Cms::SitePermission

  included do
    set_permission_name "opendata_histories", :read

    default_scope ->{ where(model: model_name.i18n_key.to_s) }
  end

  def previewable?(opts = {})
    cur_user = opts[:user]
    return false if cur_user.blank?

    cur_user.cms_user.cms_role_permit_any?(site, :read_opendata_histories)
  end
end
