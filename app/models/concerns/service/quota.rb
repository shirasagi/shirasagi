module Service::Quota
  extend ActiveSupport::Concern
  extend SS::Translation

  def reload_quota_used
    self.base_quota_used = find_base_quota_used
    self.cms_quota_used = find_cms_quota_used
    self.gws_quota_used = find_gws_quota_used
    self.webmail_quota_used = find_webmail_quota_used
    self
  end

  def find_base_quota_used
    base_db_used + base_files_used
  end

  def find_cms_quota_used
    cms_db_used + cms_files_used
  end

  def find_gws_quota_used
    gws_db_used + gws_files_used
  end

  def find_webmail_quota_used
    webmail_db_used + webmail_files_used
  end

  private

  def base_db_used
    org_ids = organizations.pluck(:id)
    size = [
      SS::PostalCode,
      SS::UserGroupHistory.any_in(gws_site_id: org_ids),
      SS::UserTitle.any_in(group_id: org_ids),
      SS::User.unscoped.any_in(organization_id: org_ids),
    ].sum { |c| c.total_bsonsize }

    organizations.each do |org|
      size += SS::Group.in_group(org).total_bsonsize
    end
    size
  end

  def cms_db_used
    site_ids = sites.pluck(:id)
    size = [
      sites,
      Chorg::Revision.any_in(site_id: site_ids),
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

    size + cms_modules_db_used
  end

  def cms_modules_db_used
    site_ids = sites.pluck(:id)
    size = [
      Board::AnpiPost.any_in(site_id: site_ids),
      Board::Post.any_in(site_id: site_ids),
      Ezine::Column.any_in(site_id: site_ids),
      Ezine::Entry.any_in(site_id: site_ids),
      Ezine::Member.any_in(site_id: site_ids),
      Ezine::TestMember.any_in(site_id: site_ids),
      History::Log.any_in(site_id: site_ids),
      Inquiry::Answer.any_in(site_id: site_ids),
      Inquiry::Column.any_in(site_id: site_ids),
      Jmaxml::Action::Base.any_in(site_id: site_ids),
      Jmaxml::ForecastRegion.any_in(site_id: site_ids),
      Jmaxml::Trigger::Base.any_in(site_id: site_ids),
      Jmaxml::TsunamiRegion.any_in(site_id: site_ids),
      Jmaxml::WaterLevelStation.any_in(site_id: site_ids),
      Job::Log.any_in(site_id: site_ids),
      Member::Group.any_in(site_id: site_ids),
      Member::ActivityLog.any_in(site_id: site_ids),
      Opendata::AppPoint.any_in(site_id: site_ids),
      Opendata::Csv2rdfSetting.any_in(site_id: site_ids),
      Opendata::DatasetGroup.any_in(site_id: site_ids),
      Opendata::DatasetPoint.any_in(site_id: site_ids),
      Opendata::IdeaComment.any_in(site_id: site_ids),
      Opendata::IdeaPoint.any_in(site_id: site_ids),
      Opendata::License.any_in(site_id: site_ids),
      Opendata::MemberNotice.any_in(site_id: site_ids),
      Rdf::Vocab.any_in(site_id: site_ids),
      Rss::WeatherXmlPage.any_in(site_id: site_ids),
    ].sum { |c| c.total_bsonsize }
  end

  def gws_db_used
    org_ids = organizations.pluck(:id)
    size = [
      Gws::CustomGroup.any_in(site_id: org_ids),
      Gws::History.any_in(site_id: org_ids),
      Gws::Link.any_in(site_id: org_ids),
      Gws::Notice.any_in(site_id: org_ids),
      Gws::Reminder.any_in(site_id: org_ids),
      Gws::Role.any_in(site_id: org_ids),
    ].sum { |c| c.total_bsonsize }

    size + gws_modules_db_used
  end

  def gws_modules_db_used
    org_ids = organizations.pluck(:id)
    size = [
      Gws::Board::Category.unscoped.any_in(site_id: org_ids),
      Gws::Board::Post.any_in(site_id: org_ids),
      Gws::Circular::Post.any_in(site_id: org_ids),
      Gws::Facility::Category.any_in(site_id: org_ids),
      Gws::Facility::Item.any_in(site_id: org_ids),
      Gws::Faq::Post.any_in(site_id: org_ids),
      Gws::Job::Log.any_in(group_id: org_ids),
      Gws::Monitor::Post.any_in(site_id: org_ids),
      Gws::Portal::GroupPortlet.any_in(site_id: org_ids),
      Gws::Portal::GroupSetting.any_in(site_id: org_ids),
      Gws::Portal::UserPortlet.any_in(site_id: org_ids),
      Gws::Portal::UserSetting.any_in(site_id: org_ids),
      Gws::Qna::Post.any_in(site_id: org_ids),
      Gws::Report::Form.any_in(site_id: org_ids),
      Gws::Schedule::Comment.any_in(site_id: org_ids),
      Gws::Schedule::Holiday.any_in(site_id: org_ids),
      Gws::Schedule::Plan.any_in(site_id: org_ids),
      Gws::Schedule::Todo.any_in(site_id: org_ids),
      Gws::Share::Folder.any_in(site_id: org_ids),
      Gws::Share::History.any_in(site_id: org_ids),
      Gws::SharedAddress::Address.any_in(site_id: org_ids),
      Gws::SharedAddress::Group.any_in(site_id: org_ids),
      Gws::StaffRecord::Group.any_in(site_id: org_ids),
      Gws::StaffRecord::Seating.any_in(site_id: org_ids),
      Gws::StaffRecord::User.any_in(site_id: org_ids),
      Gws::StaffRecord::Year.any_in(site_id: org_ids),
      Gws::Workflow::File.any_in(site_id: org_ids),
      Gws::Workflow::Form.any_in(site_id: org_ids),
    ].sum { |c| c.total_bsonsize }
  end

  def webmail_db_used
    size = [
      Webmail::AddressGroup,
      Webmail::Address,
      Webmail::Filter,
      Webmail::Mail,
      Webmail::Mailbox,
      Webmail::Quota,
      Webmail::Signature,
    ].sum { |c| c.total_bsonsize }
  end

  def base_files_used
    org_ids = organizations.pluck(:id)
    criteria = SS::File.any_in(site_id: org_ids).where(model: 'ss/temp_file')

    size = criteria.total_bsonsize + aggregate_files_used(criteria)
  end

  def cms_files_used
    site_ids = sites.pluck(:id)
    criteria = SS::File.any_in(site_id: site_ids).where(model: { '$not' => /^(ss|gws)\// })

    size = criteria.total_bsonsize + aggregate_files_used(criteria)

    sites.each do |site|
      dir = site.root_path
      next unless ::File.exists?(dir)
      size += `du -bs #{dir}`.sub(/\s.*/m, '').to_i
    end
    size
  end

  def gws_files_used
    org_ids = organizations.pluck(:id)
    criteria = SS::File.any_in(site_id: org_ids).where(model: /^gws\//)

    size = criteria.total_bsonsize + aggregate_files_used(criteria)
  end

  def webmail_files_used
    dir = "#{Rails.root}/private/files/webmail_files"
    return 0 unless ::File.exists?(dir)
    `du -bs #{dir}`.sub(/\s.*/m, '').to_i
  end

  def aggregate_files_used(criteria)
    return 0 unless criteria.exists?

    criteria.klass.collection.aggregate([
      {
        '$match' => criteria.selector
      }, {
        '$lookup' => {
          from: criteria.klass.collection_name.to_s,
          localField: "_id",
          foreignField: "original_id",
          as: "thumb"
        }
      }, {
        '$project' => {
          size: { '$sum' => ['$size', { '$sum' => '$thumb.size' }] }
        }
      }, {
        '$group' => {
          _id: nil,
          size: { '$sum' => '$size' }
        }
      }
    ]).first.try(:[], :size) || 0
  end
end
