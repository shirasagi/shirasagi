#frozen_string_literal: true

module Gws
  extend Sys::ModulePermission

  module_function

  mattr_accessor(:module_usable_handlers) { {} }

  # 200 = 80 for japanese name + 120 for english name
  # 日本語タイトルと英語タイトルとをスラッシュで連結して、一つのページとして運用することを想定
  mattr_reader(:max_name_length, default: 200)

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

  MODULES_BOUND_TO_SITE = Set.new(%w(
    Gws::Attendance::History
    Gws::Attendance::Record
    Gws::Attendance::TimeCard
    Gws::Board::Category
    Gws::Board::Post
    Gws::Bookmark::Item
    Gws::Bookmark::Folder
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
    Gws::Workflow2::File
    Gws::Workflow2::Form::Application
    Gws::Workflow2::Form::Category
    Gws::Workflow2::Form::External
    Gws::Workflow2::Form::Purpose
    Gws::Workflow2::Route
    Gws::Tabular::Space
    Gws::Tabular::Form
    Gws::Tabular::FormRelease
    Gws::Tabular::View::Base
  )).freeze

  MODULES_BOUND_TO_GROUP = Set.new(%w(
    Gws::Job::Log
    Gws::Task
  )).freeze

  MODULES_BOUND_TO_GROUPS = Set.new(%w(
    Gws::User
    Gws::Workflow::Route
  )).freeze

  MODULES_COMMON = Set.new(%w(
    Gws::User
  )).freeze

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
      criteria = klass.all.unscoped.any_in(site_id: org_ids)
      if criteria.respond_to?(:used_size)
        criteria.used_size
      else
        criteria.total_bsonsize
      end
    end
    size += filter.call(MODULES_BOUND_TO_GROUP).map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(group_id: org_ids).total_bsonsize
    end
    size += filter.call(MODULES_BOUND_TO_GROUPS).map(&:constantize).sum do |klass|
      klass.all.unscoped.any_in(group_ids: group_ids).total_bsonsize
    end
    size += _gws_tabular_file_used(org_ids)
    size
  end

  def _gws_tabular_file_used(org_ids)
    form_ids = Gws::Tabular::Form.unscoped.any_in(site_id: org_ids).pluck(:id)
    return 0 if form_ids.blank?

    file_collection_names = form_ids.map { |form_id| "gws_tabular_file_#{form_id}" }
    file_collections = Mongoid.default_client.collections.select do |collection|
      file_collection_names.include?(collection.name)
    end
    return 0 if file_collections.blank?

    file_collections.sum do |collection|
      pipes = [
        { "$group" => { _id: nil, total_object_size: { "$sum" => { "$bsonSize" => "$$ROOT" } } } },
      ]
      result = collection.aggregate(pipes)
      data = result.first
      next 0 if data.blank?

      data["total_object_size"] || 0
    end
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

  def id_name_hash(items, name_method: :name)
    items.map { |m| [ m.id.to_s, m.send(name_method) ] }.to_h
  end

  def public_dir_path(site, file)
    root_path = site.root_path
    return if root_path.blank?
    return if !root_path.start_with?(Rails.root.to_s)

    path = ::File.join("fs", file.id.to_s.chars.join("/"), "_")
    path = ::File.expand_path(path, root_path)
    return if !path.start_with?(root_path)

    path
  end

  def public_file_path(site, file)
    dir = public_dir_path(site, file)
    return if dir.blank?

    path = ::File.expand_path(file.filename, dir)
    return if !path.start_with?(Rails.root.to_s)

    path
  end

  def publish_file(site, file)
    return if site.blank? || file.blank?

    dir = Gws.public_dir_path(site, file)
    return if dir.blank?

    SS::FilePublisher.publish(file, dir)
  end

  def depublish_file(site, file)
    return if site.blank? || file.blank?

    dir = Gws.public_dir_path(site, file)
    return if dir.blank?

    SS::FilePublisher.depublish(file, dir)
  end

  def service_account_users
    return @service_account_users if defined? @service_account_users

    unless SS.config.gws.service_account
      @service_account_users = SS::EMPTY_SET
      return @service_account_users
    end

    users = SS.config.gws.service_account["users"]
    unless users
      @service_account_users = SS::EMPTY_SET
      return @service_account_users
    end

    users = users.map { _1.to_s.strip }
    @service_account_users = Set.new(users)
  end

  def service_account?(user)
    service_account_users.include?(user.uid)
  end
end
