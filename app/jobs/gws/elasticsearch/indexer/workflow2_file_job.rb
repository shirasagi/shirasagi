class Gws::Elasticsearch::Indexer::Workflow2FileJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Workflow2::File

  class << self
    def collect_file_ids_was_for_save(item)
      if item.form.blank?
        return super
      end

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
      if item.form.blank?
        return super
      end

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
    "#{index_type}-workflow2-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        @id = item.id.to_s
        @item = item
        puts item.name

        y << convert_to_doc
        item_files.each { |file| y << convert_file_to_doc(file) }
      ensure
        @id = nil
        @item = nil
      end
    end
  end

  def convert_to_doc
    doc = { collection_name: index_type.to_s }
    Gws::Elasticsearch.mappings_keys.each do |key|
      if respond_to?("build_#{key}", true)
        send("build_#{key}", doc)
      end
    end

    [ "#{index_type}-workflow2-#{item.id}", doc ]
  end

  def convert_file_to_doc(file)
    doc = { collection_name: index_type.to_s }
    Gws::Elasticsearch.mappings_keys.each do |key|
      if respond_to?("build_file_#{key}", true)
        send("build_file_#{key}", doc, file)
      end
    end

    [ "file-#{file.id}", doc ]
  end

  def item_text
    if item.form.present?
      collect_form_text
    else
      item.text
    end
  end

  def item_state
    # gws/workflow/file は、承認者や回覧者の設定に応じて自動的に閲覧権限や承認権限が付与されるので、常に closed とする。
    'closed'
  end

  def collect_form_text
    texts = []
    item.column_values.each do |column_value|
      texts << column_value.to_es
    end
    texts.compact
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

  def item_group_ids
    # gws/workflow2/file は、承認者や回覧者の設定に応じて自動的に閲覧権限や承認権限が付与される。
    # 全文検索で、自動的に付与された閲覧権限に対応するため、user_ids に閲覧可能なユーザーを追加する。
    item_member_group_ids
  end

  def item_user_ids
    # gws/workflow2/file は、承認者や回覧者の設定に応じて自動的に閲覧権限や承認権限が付与される。
    # 全文検索で、自動的に付与された閲覧権限に対応するため、user_ids に閲覧可能なユーザーを追加する。
    item_member_ids
  end

  def item_member_group_ids
    member_group_ids = []

    if Workflow::Approver::WORKFLOW_STATE_COMPLETES.include?(item.workflow_state) && item.destination_group_ids
      member_group_ids += item.destination_group_ids
    end

    member_group_ids
  end

  WORKFLOW_STATE_RUNNINGS = begin
    Workflow::Approver::WORKFLOW_STATE_COMPLETES +
      [ Workflow::Approver::WORKFLOW_STATE_REQUEST, Workflow::Approver::WORKFLOW_STATE_REMAND ]
  end.freeze

  # rubocop:disable Rails/Pluck
  def item_member_ids
    member_ids = []
    if item.workflow_user_id
      member_ids << item.workflow_user_id
    end
    if item.workflow_agent_id
      member_ids << item.workflow_agent_id
    end
    if item.workflow_user_id.blank? && item.workflow_agent_id.blank? && item.user_id
      # fallback to user_id
      member_ids << item.user_id
    end

    if WORKFLOW_STATE_RUNNINGS.include?(item.workflow_state)
      available_states = %w(request approve remand)
      approvers = item.workflow_approvers.select { |approver| available_states.include?(approver[:state]) }
      member_ids += approvers.map { |approver| approver[:user_id] }
    end
    if Workflow::Approver::WORKFLOW_STATE_COMPLETES.include?(item.workflow_state)
      available_states = %w(seen unseen)
      circulations = item.workflow_circulations.select { |circulation| available_states.include?(circulation[:state]) }
      member_ids += circulations.map { |circulation| circulation[:user_id] }

      if item.destination_user_ids
        member_ids += item.destination_user_ids
      end
    end

    member_ids.uniq!
    member_ids.sort!
    member_ids
  end
  # rubocop:enable Rails/Pluck

  def item_files
    SS::File.in(id: self.class.collect_file_ids_for_save(item))
  end

  def build_url(doc)
    doc[:url] = url_helpers.gws_workflow2_file_path(site: site, state: 'all', id: item)
  end

  def build_name(doc)
    doc[:name] = item.name
  end

  def build_text(doc)
    doc[:text] = item_text
  end

  def build_categories(doc)
    doc[:categories] = item.categories.pluck(:name) if item.respond_to?(:categories)
  end

  def build_state(doc)
    doc[:release_date] = item_release_date
    doc[:close_date] = item_close_date
    doc[:released] = item_released
    doc[:state] = item_state
  end

  def build_user_name(doc)
    doc[:user_name] = find_workflow_user_custom_data_value(item, "name")
  end

  def build_user_ids(doc)
    doc[:group_ids] = item_group_ids
    # doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item_user_ids
  end

  def build_updated(doc)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)
  end

  def build_file_url(doc, file)
    doc[:url] = url_helpers.gws_workflow2_file_path(site: site, state: 'all', id: item, anchor: "file-#{file.id}")
  end

  def build_file_name(doc, file)
    doc[:name] = file.name
  end

  def build_file_lang(doc, file)
    build_lang(doc)
  end

  def build_file_categories(doc, file)
    build_categories(doc)
  end

  def build_file_file(doc, file)
    doc[:file] = {
      extname: file.extname.upcase,
      size: file.size
    }
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
  end

  def build_file_state(doc, file)
    build_state(doc)
  end

  def build_file_user_name(doc, file)
    build_user_name(doc)
  end

  def build_file_user_ids(doc, file)
    build_user_ids(doc)
  end

  def build_file_updated(doc, file)
    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)
  end

  def find_workflow_user_custom_data_value(item, name)
    return if item.workflow_user_custom_data.blank?

    custom_data = item.workflow_user_custom_data.find { |data| data["name"] == name }
    return unless custom_data

    custom_data["value"]
  end
end
