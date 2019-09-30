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

  def self.find_cms_quota_used(site_criteria)
    Cms.cms_db_used(site_criteria) + Cms.cms_files_used(site_criteria)
  end

  def self.cms_db_used(site_criteria)
    site_ids = site_criteria.pluck(:id)
    size = [
      site_criteria,
      ::Chorg::Revision.any_in(site_id: site_ids),
      Cms::BodyLayout.any_in(site_id: site_ids),
      Cms::EditorTemplate.any_in(site_id: site_ids),
      Cms::Layout.any_in(site_id: site_ids),
      Cms::LoopSetting.any_in(site_id: site_ids),
      Cms::MaxFileSize.any_in(site_id: site_ids),
      Cms::Member.any_in(site_id: site_ids),
      Cms::Node.any_in(site_id: site_ids),
      Cms::Notice.any_in(site_id: site_ids),
      Cms::PageSearch.any_in(site_id: site_ids),
      Cms::Page.any_in(site_id: site_ids),
      Cms::Part.any_in(site_id: site_ids),
      Cms::Role.any_in(site_id: site_ids),
      Cms::SourceCleanerTemplate.any_in(site_id: site_ids),
      Cms::ThemeTemplate.any_in(site_id: site_ids),
      Cms::WordDictionary.any_in(site_id: site_ids),
    ].sum { |c| c.total_bsonsize }

    size + Cms.cms_modules_db_used(site_criteria)
  end

  def self.cms_modules_db_used(site_criteria)
    site_ids = site_criteria.pluck(:id)
    [
      ::Board::AnpiPost.any_in(site_id: site_ids),
      ::Board::Post.any_in(site_id: site_ids),
      ::Ezine::Column.any_in(site_id: site_ids),
      ::Ezine::Entry.any_in(site_id: site_ids),
      ::Ezine::Member.any_in(site_id: site_ids),
      ::Ezine::TestMember.any_in(site_id: site_ids),
      ::History::Log.any_in(site_id: site_ids),
      ::Inquiry::Answer.any_in(site_id: site_ids),
      ::Inquiry::Column.any_in(site_id: site_ids),
      ::Jmaxml::Action::Base.any_in(site_id: site_ids),
      ::Jmaxml::ForecastRegion.any_in(site_id: site_ids),
      ::Jmaxml::Trigger::Base.any_in(site_id: site_ids),
      ::Jmaxml::TsunamiRegion.any_in(site_id: site_ids),
      ::Jmaxml::WaterLevelStation.any_in(site_id: site_ids),
      ::Job::Log.any_in(site_id: site_ids),
      ::Member::Group.any_in(site_id: site_ids),
      ::Member::ActivityLog.any_in(site_id: site_ids),
      ::Opendata::AppPoint.any_in(site_id: site_ids),
      ::Opendata::Csv2rdfSetting.any_in(site_id: site_ids),
      ::Opendata::DatasetGroup.any_in(site_id: site_ids),
      ::Opendata::DatasetPoint.any_in(site_id: site_ids),
      ::Opendata::IdeaComment.any_in(site_id: site_ids),
      ::Opendata::IdeaPoint.any_in(site_id: site_ids),
      ::Opendata::License.any_in(site_id: site_ids),
      ::Opendata::MemberNotice.any_in(site_id: site_ids),
      ::Rdf::Vocab.any_in(site_id: site_ids),
      ::Rss::WeatherXmlPage.any_in(site_id: site_ids),
    ].sum { |c| c.total_bsonsize }
  end

  def self.cms_files_used(site_criteria)
    site_ids = site_criteria.pluck(:id)
    criteria = SS::File.any_in(site_id: site_ids).where(model: { '$not' => /^(ss|gws)\// })

    size = criteria.total_bsonsize + criteria.aggregate_files_used

    site_criteria.each do |site|
      dir = site.root_path
      next unless ::File.exists?(dir)
      size += `du -bs #{Shellwords.escape(dir)}`.sub(/\s.*/m, '').to_i
    end
    size
  end

end
