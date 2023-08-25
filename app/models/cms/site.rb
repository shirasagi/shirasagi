class Cms::Site
  include SS::Model::Site
  include SS::Relation::File
  include Cms::SitePermission
  include Cms::Addon::PageSetting
  include Cms::Addon::Site::NodeSetting
  include Cms::Addon::DefaultReleasePlan
  include SS::Addon::MobileSetting
  include SS::Addon::MapSetting
  include SS::Addon::KanaSetting
  include SS::Addon::OpenGraphSetting
  include SS::Addon::FacebookSetting
  include SS::Addon::TwitterSetting
  include SS::Addon::LineSetting
  include SS::Addon::KintoneSetting
  include SS::Addon::FileSetting
  include SS::Addon::MailSetting
  include SS::Addon::ApproveSetting
  include SS::Addon::TrashSetting
  include Opendata::Addon::SiteSetting
  include SS::Addon::EditorSetting
  include SS::Addon::LogoSetting
  include SS::Addon::Elasticsearch::SiteSetting
  include SS::Addon::Translate::SiteSetting
  include SS::Addon::PartnerSetting
  include SS::Addon::InquirySetting
  include SS::Addon::WorkflowSetting
  include SS::Addon::SourceCleaner::SiteSetting
  include SS::Addon::SiteUsage
  include SS::Addon::GenerateLock
  include SS::Addon::MaintenanceMode
  include Cms::SyntaxChecker::MainSetting
  include Cms::SyntaxChecker::UrlSchemeSetting

  set_permission_name "cms_sites", :edit
end
