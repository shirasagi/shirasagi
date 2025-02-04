#frozen_string_literal: true

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

  MODULES_BOUND_TO_SITE = Set.new(%w(
    ::Ads::AccessLog
    ::Board::AnpiPost
    ::Board::Post
    ::Chat::Category
    ::Chat::History
    ::Chat::Intent
    ::Chat::LineBot::ExistsPhrase
    ::Chat::LineBot::RecordPhrase
    ::Chat::LineBot::Session
    ::Chat::LineBot::UsedTime
    ::Chorg::Changeset
    ::Chorg::Revision
    ::Cms::ApiToken
    ::Cms::BodyLayout
    ::Cms::CheckLinks::Error::Base
    ::Cms::CheckLinks::IgnoreUrl
    ::Cms::CheckLinks::Report
    ::Cms::Column::Base
    ::Cms::Command
    ::Cms::EditorTemplate
    ::Cms::File
    ::Cms::Form
    ::Cms::FormDb
    ::Cms::FormDb::ImportLog
    ::Cms::GenerationReport::Title
    ::Cms::ImageResize
    ::Cms::ImportJobFile
    ::Cms::InitColumn
    ::Cms::Layout
    ::Cms::Ldap::Import
    ::Cms::Line::DeliverCategory::Base
    ::Cms::Line::DeliverCondition
    ::Cms::Line::DeliverPlan
    ::Cms::Line::EventSession
    ::Cms::Line::FacilitySearch::Category
    ::Cms::Line::MailHandler
    ::Cms::Line::Message
    ::Cms::Line::Richmenu::Group
    ::Cms::Line::Richmenu::Menu
    ::Cms::Line::Richmenu::Registration
    ::Cms::Line::Service::Group
    ::Cms::Line::Service::Hook::Base
    ::Cms::Line::Statistic
    ::Cms::Line::Template::Base
    ::Cms::Line::TestMember
    ::Cms::LoopSetting
    ::Cms::MaxFileSize
    ::Cms::Member
    ::Cms::Michecker::Result
    ::Cms::Node
    ::Cms::Notice
    ::Cms::Page
    ::Cms::PageIndexQueue
    ::Cms::PageRelease
    ::Cms::PageSearch
    ::Cms::Part
    ::Cms::Role
    ::Cms::SiteSearch::History::Log
    ::Cms::SnsPostLog::Base
    ::Cms::SourceCleanerTemplate
    ::Cms::Task
    ::Cms::ThemeTemplate
    ::Cms::WordDictionary
    ::Ezine::Column
    ::Ezine::Entry
    ::Ezine::Member
    ::Ezine::TestMember
    ::Guide::Diagram::Point
    ::History::Log
    ::History::Trash
    ::Inquiry::Answer
    ::Inquiry::Column
    ::Jmaxml::Action::Base
    ::Jmaxml::ForecastRegion
    ::Jmaxml::QuakeRegion
    ::Jmaxml::Trigger::Base
    ::Jmaxml::TsunamiRegion
    ::Jmaxml::WaterLevelStation
    ::Job::Log
    ::Kana::Dictionary
    ::Map::Geolocation
    ::Member::ActivityLog
    ::Member::Bookmark
    ::Member::Group
    ::Opendata::AppPoint
    ::Opendata::Csv2rdfSetting
    ::Opendata::DatasetAccessReport
    ::Opendata::DatasetFavorite
    ::Opendata::DatasetGroup
    ::Opendata::DatasetPoint
    ::Opendata::Harvest::Exporter
    ::Opendata::Harvest::Exporter::GroupSetting
    ::Opendata::Harvest::Exporter::OwnerOrgSetting
    ::Opendata::Harvest::Importer
    ::Opendata::Harvest::Importer::CategorySetting
    ::Opendata::Harvest::Importer::EstatCategorySetting
    ::Opendata::Harvest::Importer::Report
    ::Opendata::IdeaComment
    ::Opendata::IdeaPoint
    ::Opendata::License
    ::Opendata::MemberNotice
    ::Opendata::Metadata::Importer
    ::Opendata::Metadata::Importer::CategorySetting
    ::Opendata::Metadata::Importer::EstatCategorySetting
    ::Opendata::Metadata::Importer::Report
    ::Opendata::ResourceBulkDownloadHistory
    ::Opendata::ResourceDatasetDownloadHistory
    ::Opendata::ResourceDownloadHistory
    ::Opendata::ResourceDownloadReport
    ::Opendata::ResourcePreviewHistory
    ::Opendata::ResourcePreviewReport
    ::Rdf::Vocab
    ::Recommend::History::Log
    ::Recommend::SimilarityScore
    ::Translate::AccessLog
    ::Translate::Lang
    ::Translate::TextCache
    ::Uploader::JobFile
    ::Voice::File
  )).freeze

  MODULES_BOUND_TO_GROUP = Set.new(%w(
    ::Cms::User
    ::Workflow::Route
  )).freeze

  MODULES_COMMON = Set.new(%w(
    ::Cms::User
  )).freeze

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
    if opts[:except] != "common" && groups.any?
      size += groups.total_bsonsize rescue 0
    end

    if opts[:except] == "common"
      modules = MODULES_BOUND_TO_SITE.reject { |klass| MODULES_COMMON.include?(klass) }
    else
      modules = MODULES_BOUND_TO_SITE
    end
    size += modules.map(&:constantize).sum do |klass|
      criteria = klass.all.unscoped.any_in(site_id: site_ids)
      if criteria.respond_to?(:used_size)
        criteria.used_size
      else
        criteria.total_bsonsize
      end
    end

    if opts[:except] == "common"
      modules = MODULES_BOUND_TO_GROUP.reject { |klass| MODULES_COMMON.include?(klass) }
    else
      modules = MODULES_BOUND_TO_GROUP
    end
    size += modules.map(&:constantize).sum do |klass|
      criteria = klass.all.unscoped.any_in(group_ids: group_ids)
      if criteria.respond_to?(:used_size)
        criteria.used_size
      else
        criteria.total_bsonsize
      end
    end

    size
  end

  def self.cms_files_used(site_criteria, _opts = {})
    site_ids = site_criteria.pluck(:id)
    criteria = SS::File.any_in(site_id: site_ids).where(model: { '$not' => /^(ss|gws|webmail)\// })

    size = criteria.total_bsonsize + criteria.aggregate_files_used

    site_criteria.each do |site|
      public_file_paths(site).each do |path|
        size += ::File.stat(path).size rescue 0
      end
    end
    size
  end

  def self.public_file_paths(site)
    dir = site.path
    fs_dir = ::File.join(dir, "fs")
    child_dirs = site.children.map(&:path)

    fs_paths = []
    files = SS::File.where(site_id: site.id)
    file_ids = files.pluck(:id)
    file_ids.each_slice(100) do |ids|
      files.in(id: ids).to_a.each do |item|
        fs_paths << item.public_path
        fs_paths << item.thumb.public_path if item.image? && item.thumb
      end
    end

    paths = []
    return paths unless ::File.exist?(dir)

    # see: https://myokoym.hatenadiary.org/entry/20100606/1275836896
    ::Dir.glob("#{dir}/**/*") do |path|
      # fs
      if (path == fs_dir) || path.start_with?(fs_dir + "/")
        paths << path if fs_paths.include?(path)
      # subsite
      elsif child_dirs.find { |child_dir| (path == child_dir) || path.start_with?(child_dir + "/") }
        next
      else
        paths << path
      end
    end
    paths
  end

  DEFAULT_SENDER_ADDRESS = begin
    default_from = SS.config.mail.default_from
    if default_from.present?
      default_from = default_from.dup
    else
      default_from = "noreply@example.jp"
    end
    default_from.freeze
  end

  def self.sender_address(*contents)
    contents.each do |content|
      if content.respond_to?(:sender_address)
        sender_address = content.sender_address
        return sender_address if sender_address.present?
      end

      if content.respond_to?(:sender_email) && content.sender_email.present?
        if content.respond_to?(:sender_name) && content.sender_name.present?
          return "#{content.sender_name} <#{content.sender_email}>"
        else
          return content.sender_email
        end
      end

      if content.respond_to?(:from_email) && content.from_email.present?
        if content.respond_to?(:from_name) && content.from_name.present?
          return "#{content.from_name} <#{content.from_email}>"
        else
          return content.from_email
        end
      end
    end

    DEFAULT_SENDER_ADDRESS
  end

  def self.generate_message_id(site)
    # see: mail/fields/message_id_field.rb#generate_message_id
    if site.present? && site.respond_to?(:domain) && site.domain.present?
      domain = site.domain
    end
    domain ||= "replace-me.example.jp"
    domain = domain.sub(/:.*$/, '') if domain.include?(":")

    "<#{::Mail.random_tag}@#{domain}.mail>"
  end

  def self.cms_page_date(released_type, released, updated, created, first_released)
    case released_type
    when "fixed"
      released || first_released || updated || created
    when "same_as_created"
      created
    when "same_as_first_released"
      first_released || updated || created
    else # same_as_updated
      updated || created
    end
  end

  def self.contains_urls(page, site:)
    if !page.is_a?(Cms::Model::Page) || page.try(:branch?)
      Cms::Page.none
    else
      Cms::Page.all.site(site).and_linking_pages(page)
    end
  end

  def self.compile_scss(source, load_paths:, filename:)
    commands = SS.config.cms.sass['commands'].dup
    unless commands.include?("--stdin")
      commands << "--stdin"
    end

    if filename
      basedir = ::File.dirname(filename)
    end
    if basedir && !load_paths.include?(basedir)
      commands << "--load-path=#{basedir}"
    end
    load_paths.each { commands << "--load-path=#{_1}" }

    output = nil
    wait_thr = Open3.popen3(*commands) do |stdin, stdout, stderr, wait_thr|
      stdin.write source
      stdin.close

      output = stdout.read
      Rails.logger.info { stderr.read }

      wait_thr
    end

    raise "sass command exited in errors" unless wait_thr.value.success?

    output
  end

  def self.unescape_html_entities(text)
    Nokogiri::HTML5.fragment(text).text
  end
end
