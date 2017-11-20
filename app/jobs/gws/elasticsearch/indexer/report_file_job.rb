class Gws::Elasticsearch::Indexer::ReportFileJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  REDIRECT = 'redirect'.freeze

  self.model = Gws::Report::File

  class << self
    def collect_file_ids_was_for_save(item)
      file_ids = []
      item.column_values.each do |column_value|
        next unless column_value.respond_to?(:file_ids_was)

        file_ids += Array(column_value.file_ids_was)
      end
      file_ids.flatten!
      file_ids.compact!
      file_ids.uniq!
      file_ids
    end

    def collect_file_ids_for_save(item)
      file_ids = []
      item.column_values.each do |column_value|
        next unless column_value.respond_to?(:file_ids)

        file_ids += Array(column_value.file_ids)
      end
      file_ids.flatten!
      file_ids.compact!
      file_ids.uniq!
      file_ids
    end
  end

  private

  def index_item_id
    "report-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
      item_files.each do |file|
        y << convert_file_to_doc(file)
      end
    end
  end

  def convert_to_doc
    doc = {}
    doc[:url] = url_helpers.gws_report_file_path(site: site, state: REDIRECT, id: item)
    doc[:name] = item.name
    doc[:mode] = 'form'
    doc[:text] = item_text
    doc[:categories] = item_categories

    doc[:release_date] = item_release_date
    doc[:close_date] = item_close_date
    doc[:released] = item_released
    doc[:state] = item.state

    doc[:user_name] = item.user_long_name
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
    doc[:permission_level] = item.permission_level

    doc[:member_ids] = item.members.pluck(:id)
    doc[:member_custom_group_ids] = item.member_custom_groups.pluck(:id)

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ "report-#{item.id}", doc ]
  end

  def convert_file_to_doc(file)
    doc = {}
    doc[:url] = url_helpers.gws_report_file_path(site: site, state: REDIRECT, id: item, anchor: "file-#{file.id}")
    doc[:name] = file.name
    # doc[:categories] = item.categories.pluck(:name)
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size

    doc[:release_date] = item_release_date
    doc[:close_date] = item_close_date
    doc[:released] = item_released
    doc[:state] = item.state

    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
    doc[:permission_level] = item.permission_level

    doc[:member_ids] = item.members.pluck(:id)
    doc[:member_custom_group_ids] = item.member_custom_groups.pluck(:id)

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def item_text
    texts = []
    item.column_values.each do |column_value|
      texts << column_value.to_es
    end
    texts.compact
  end

  def item_categories
    item.categories.pluck(:name) if item.respond_to?(:categories)
  end

  def item_release_date
    item.release_date.try(:iso8601) if item.respond_to?(:release_date)
  end

  def item_close_date
    item.close_date.try(:iso8601) if item.respond_to?(:close_date)
  end

  def item_released
    ret = item.released.try(:iso8601) if item.respond_to?(:released)
    ret ||= item.updated.try(:iso8601)
    ret
  end

  def item_files
    SS::File.in(id: self.class.collect_file_ids_for_save(item))
  end
end
