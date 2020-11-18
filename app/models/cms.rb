module Cms
  extend Sys::ModulePermission

  # factory method for Liquid::Template
  def self.parse_liquid(source, registers)
    template = Liquid::Template.parse(source)

    template.assigns["parts"] = SS::LiquidPartDrop.get(registers[:cur_site])

    registers.each do |key, value|
      template.registers[key] = value
    end

    template
  end

  def self.find_cms_quota_used(site_criteria, opts = {})
    Cms.cms_db_used(site_criteria, opts) + Cms.cms_files_used(site_criteria, opts)
  end

  MODULES_BOUND_TO_SITE = %w(
    ::Ads::AccessLog
    ::Board::AnpiPost
    ::Board::Post
    ::Chat::Category
    ::Chat::History
    ::Chat::Intent
    ::Chorg::Changeset
    ::Chorg::Revision
    ::Cms::BodyLayout
    ::Cms::Column::Base
    ::Cms::Command
    ::Cms::EditorTemplate
    ::Cms::Form
    ::Cms::ImportJobFile
    ::Cms::InitColumn
    ::Cms::Layout
    ::Cms::LoopSetting
    ::Cms::MaxFileSize
    ::Cms::Member
    ::Cms::Node
    ::Cms::Notice
    ::Cms::Page
    ::Cms::PageRelease
    ::Cms::PageSearch
    ::Cms::Part
    ::Cms::Role
    ::Cms::Role
    ::Cms::SourceCleanerTemplate
    ::Cms::ThemeTemplate
    ::Cms::WordDictionary
    ::Ezine::Column
    ::Ezine::Entry
    ::Ezine::Member
    ::Ezine::TestMember
    ::History::Log
    ::Inquiry::Answer
    ::Inquiry::Column
    ::Jmaxml::Action::Base
    ::Jmaxml::Filter
    ::Jmaxml::ForecastRegion
    ::Jmaxml::QuakeRegion
    ::Jmaxml::Trigger::Base
    ::Jmaxml::TsunamiRegion
    ::Jmaxml::WaterLevelStation
    ::Job::Log
    ::Kana::Dictionary
    ::Ldap::Import
    ::Member::ActivityLog
    ::Member::Group
    ::Opendata::AppPoint
    ::Opendata::Csv2rdfSetting
    ::Opendata::DatasetGroup
    ::Opendata::DatasetPoint
    ::Opendata::Harvest::Exporter
    ::Opendata::Harvest::Exporter::DatasetRelation
    ::Opendata::Harvest::Exporter::GroupSetting
    ::Opendata::Harvest::Exporter::OwnerOrgSetting
    ::Opendata::Harvest::Importer
    ::Opendata::Harvest::Importer::CategorySetting
    ::Opendata::Harvest::Importer::EstatCategorySetting
    ::Opendata::Harvest::Importer::Report
    ::Opendata::Harvest::Importer::ReportDataset
    ::Opendata::IdeaComment
    ::Opendata::IdeaPoint
    ::Opendata::License
    ::Opendata::MemberNotice
    ::Opendata::ResourceBulkDownloadHistory
    ::Opendata::ResourceDatasetDownloadHistory
    ::Opendata::ResourceDownloadHistory
    ::Opendata::ResourcePreviewHistory
    ::Rdf::Class
    ::Rdf::Prop
    ::Rdf::Vocab
    ::Recommend::History::Log
    ::Recommend::SimilarityScore
    ::Voice::File
  ).freeze

  MODULES_BOUND_TO_GROUP = %w(
    ::Cms::User
    ::Workflow::Route
  ).freeze

  MODULES_COMMON = %w(
    ::Cms::User
  ).freeze

  def self.cms_db_used(site_criteria, opts = {})
    site_ids = site_criteria.pluck(:id)
    site_group_ids = site_criteria.pluck(:group_ids).flatten.uniq
    organization_group_ids = Cms::Group.all.unscoped.in(id: site_group_ids).organizations.pluck(:id)
    organization_group_names = Cms::Group.all.unscoped.in(id: organization_group_ids).pluck(:name)
    conditions = organization_group_names.map { |name| { name: /^#{::Regexp.escape(name)}(\/|$)/ } }
    if conditions.present?
      groups = Cms::Group.all.unscoped.where("$and" => [{ "$or" => conditions }])
    else
      groups = Cms::Group.none
    end
    group_ids = groups.pluck(:id)

    size = site_criteria.total_bsonsize
    if opts[:except] != "common" && !groups.none?
      size += groups.total_bsonsize rescue 0
    end

    if opts[:except] == "common"
      modules = MODULES_BOUND_TO_SITE.reject { |klass| MODULES_COMMON.include?(klass) }
    else
      modules = MODULES_BOUND_TO_SITE
    end
    size += modules.map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(site_id: site_ids).total_bsonsize
    end

    if opts[:except] == "common"
      modules = MODULES_BOUND_TO_GROUP.reject { |klass| MODULES_COMMON.include?(klass) }
    else
      modules = MODULES_BOUND_TO_GROUP
    end
    size += modules.map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(group_ids: group_ids).total_bsonsize
    end

    size
  end

  def self.cms_files_used(site_criteria, _opts = {})
    site_ids = site_criteria.pluck(:id)
    criteria = SS::File.any_in(site_id: site_ids).where(model: { '$not' => /^(ss|gws|webmail)\// })

    size = criteria.total_bsonsize + criteria.aggregate_files_used

    site_criteria.each do |site|
      dir = site.root_path
      next unless ::File.exists?(dir)
      # see: https://myokoym.hatenadiary.org/entry/20100606/1275836896
      ::Dir.glob("#{dir}/**/*") do |path|
        size += ::File.stat(path).size rescue 0
      end
    end
    size
  end
end
