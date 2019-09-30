module Gws
  extend Sys::ModulePermission

  module_function

  mattr_accessor(:module_usable_handlers) { {} }

  def module_usable(name, proc = nil, &block)
    proc = block if block_given?
    module_usable_handlers[name.to_sym] = proc
  end

  def module_usable?(name, site, user)
    handler = module_usable_handlers[name.to_sym]
    return true if handler.nil?

    handler.call(site, user)
  end

  def find_gws_quota_used(organizations_criteria)
    Gws.gws_db_used(organizations_criteria) + Gws.gws_files_used(organizations_criteria)
  end

  def gws_db_used(organizations_criteria)
    org_ids = organizations_criteria.pluck(:id)
    size = [
      Gws::CustomGroup.any_in(site_id: org_ids),
      Gws::History.any_in(site_id: org_ids),
      Gws::Link.any_in(site_id: org_ids),
      Gws::Notice::Post.any_in(site_id: org_ids),
      Gws::Reminder.any_in(site_id: org_ids),
      Gws::Role.any_in(site_id: org_ids),
    ].sum { |c| c.total_bsonsize }

    size + Gws.gws_modules_db_used(organizations_criteria)
  end

  def gws_modules_db_used(organizations_criteria)
    org_ids = organizations_criteria.pluck(:id)
    [
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

  def gws_files_used(organizations_criteria)
    org_ids = organizations_criteria.pluck(:id)
    criteria = SS::File.any_in(site_id: org_ids).where(model: /^gws\//)

    criteria.total_bsonsize + criteria.aggregate_files_used
  end
end
