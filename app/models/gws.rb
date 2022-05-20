module Gws
  extend Sys::ModulePermission

  module_function

  mattr_accessor(:module_usable_handlers) { {} }

  def module_usable(name, proc = nil, &block)
    proc = block if block
    module_usable_handlers[name.to_sym] = proc
  end

  def module_usable?(name, site, user)
    handler = module_usable_handlers[name.to_sym]
    return true if handler.nil?

    handler.call(site, user)
  end

  def find_gws_quota_used(organizations_criteria, opts = {})
    Gws.gws_db_used(organizations_criteria, opts) + Gws.gws_files_used(organizations_criteria, opts)
  end

  MODULES_BOUND_TO_SITE = %w(
    Gws::Attendance::History
    Gws::Attendance::Record
    Gws::Attendance::TimeCard
    Gws::Board::Category
    Gws::Board::Post
    Gws::Bookmark
    Gws::Chorg::Changeset
    Gws::Chorg::Revision
    Gws::Circular::Post
    Gws::Column::Base
    Gws::Contrast
    Gws::CustomGroup
    Gws::Discussion::Base
    Gws::Facility::Category
    Gws::Facility::Item
    Gws::Faq::Post
    Gws::History
    Gws::HistoryArchiveFile
    Gws::Link
    Gws::Link
    Gws::Memo::Filter
    Gws::Memo::Folder
    Gws::Memo::Forward
    Gws::Memo::List
    Gws::Memo::Message
    Gws::Memo::Signature
    Gws::Memo::Template
    Gws::Monitor::Post
    Gws::Notice::Comment
    Gws::Notice::Folder
    Gws::Notice::Post
    Gws::Portal::GroupPortlet
    Gws::Portal::GroupSetting
    Gws::Portal::UserPortlet
    Gws::Portal::UserSetting
    Gws::Qna::Post
    Gws::Reminder
    Gws::Report::File
    Gws::Report::Form
    Gws::Role
    Gws::Schedule::Comment
    Gws::Schedule::Holiday
    Gws::Schedule::Plan
    Gws::Schedule::Todo
    Gws::Schedule::TodoComment
    Gws::Share::Folder
    Gws::Share::History
    Gws::SharedAddress::Address
    Gws::SharedAddress::Group
    Gws::StaffRecord::Group
    Gws::StaffRecord::Seating
    Gws::StaffRecord::User
    Gws::StaffRecord::Year
    Gws::Survey::File
    Gws::Survey::Form
    Gws::UserForm
    Gws::UserFormData
    Gws::UserPresence
    Gws::UserTitle
    Gws::UserOccupation
    Gws::Workflow::File
    Gws::Workflow::Form
  ).freeze

  MODULES_BOUND_TO_GROUP = %w(
    Gws::Job::Log
    Gws::Chorg::Task
    Gws::Task
  ).freeze

  MODULES_BOUND_TO_GROUPS = %w(
    Gws::User
    Gws::Workflow::Route
  ).freeze

  MODULES_COMMON = %w(
    Gws::User
  ).freeze

  def gws_db_used(organizations_criteria, opts = {})
    org_ids, org_names = organizations_criteria.pluck(:id, :name).transpose
    org_ids ||= []
    conditions = org_names.try { org_names.map { |name| { name: /^#{::Regexp.escape(name)}(\/|$)/ } } }
    groups = conditions.try { Gws::Group.all.where("$and" => [{ "$or" => conditions }]) } || Gws::Group.none
    group_ids = groups.pluck(:id)

    filter = proc { |array| array }
    if opts[:except] == "common"
      filter = proc { |array| array.reject { |klass| MODULES_COMMON.include?(klass) } }
    end

    size = opts[:except] == "common" ? 0 : groups.total_bsonsize
    size += filter.call(MODULES_BOUND_TO_SITE).map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(site_id: org_ids).total_bsonsize
    end
    size += filter.call(MODULES_BOUND_TO_GROUP).map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(group_id: org_ids).total_bsonsize
    end
    size += filter.call(MODULES_BOUND_TO_GROUPS).map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(group_ids: group_ids).total_bsonsize
    end
    size
  end

  def gws_files_used(organizations_criteria, _opts = {})
    org_ids = organizations_criteria.pluck(:id)
    criteria = SS::File.any_in(site_id: org_ids).where(model: /^gws\//)

    criteria.total_bsonsize + criteria.aggregate_files_used
  end

  def generate_message_id(site)
    # see: mail/fields/message_id_field.rb#generate_message_id
    if site.present? && site.respond_to?(:canonical_domain) && site.canonical_domain.present?
      domain = site.canonical_domain
    end
    domain ||= SS.config.gws.canonical_domain
    domain = domain.sub(/:.*$/, '') if domain.include?(":")

    "<#{::Mail.random_tag}@#{domain}.mail>"
  end
end
