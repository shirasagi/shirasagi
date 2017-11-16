class Gws::Elasticsearch::Indexer::WorkflowFileJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Workflow::File

  private

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
    doc[:url] = url_helpers.gws_workflow_file_path(site: site, state: 'all', id: item)
    doc[:name] = item.name
    doc[:mode] = item.form.present? ? 'form' : 'standard'
    if item.form.present?
      doc[:text] = collect_form_text
    else
      doc[:text] = item.text
    end
    doc[:categories] = item.categories.pluck(:name) if item.respond_to?(:categories)

    doc[:release_date] = item.release_date.try(:iso8601) if item.respond_to?(:release_date)
    doc[:close_date] = item.close_date.try(:iso8601) if item.respond_to?(:close_date)
    doc[:released] = item.released.try(:iso8601) if item.respond_to?(:released)
    doc[:released] ||= item.updated.try(:iso8601)
    doc[:state] = item.state

    doc[:user_name] = item.user_long_name
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
    doc[:permission_level] = item.permission_level

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ "workflow-#{item.id}", doc ]
  end

  def convert_file_to_doc(file)
    doc = {}
    doc[:url] = url_helpers.gws_workflow_file_path(site: site, state: 'all', id: item, anchor: "file-#{file.id}")
    doc[:name] = file.name
    # doc[:categories] = item.categories.pluck(:name)
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size

    doc[:release_date] = item.release_date.try(:iso8601) if item.respond_to?(:release_date)
    doc[:close_date] = item.close_date.try(:iso8601) if item.respond_to?(:close_date)
    doc[:released] = item.released.try(:iso8601) if item.respond_to?(:released)
    doc[:released] ||= item.updated.try(:iso8601)
    doc[:state] = item.state

    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
    doc[:permission_level] = item.permission_level

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def collect_form_text
    texts = []
    item.column_values.each do |column_value|
      texts << column_value.to_es
    end
    texts.compact
  end

  def item_files
    if item.form.present?
      collect_form_files
    else
      item.files
    end
  end

  def collect_form_files
    file_ids = []
    item.column_values.each do |column_value|
      next unless column_value.respond_to?(:file_ids)

      file_ids += Array(column_value.file_ids)
    end
    SS::File.in(id: file_ids.flatten.compact)
  end
end
