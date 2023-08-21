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
    Cms.find_cms_quota_used(sites, except: "common")
  end

  def find_gws_quota_used
    Gws.find_gws_quota_used(organizations, except: "common")
  end

  def find_webmail_quota_used
    Webmail.find_webmail_quota_used(except: "common")
  end

  private

  def base_db_used
    org_ids = organizations.pluck(:id)
    size = [
      SS::PostalCode,
      SS::UserGroupHistory.any_in(gws_site_id: org_ids),
      SS::UserTitle.any_in(group_id: org_ids),
      SS::UserOccupation.any_in(group_id: org_ids),
      SS::User.unscoped.any_in(organization_id: org_ids),
    ].sum { |c| c.total_bsonsize }

    organizations.each do |org|
      size += SS::Group.in_group(org).total_bsonsize
    end

    size
  end

  def base_files_used
    org_ids = organizations.pluck(:id)
    criteria = SS::File.any_in(site_id: org_ids).where(model: 'ss/temp_file')

    criteria.total_bsonsize + criteria.aggregate_files_used
  end
end
