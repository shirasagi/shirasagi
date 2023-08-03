class Gws::Elasticsearch::Indexer::WorkflowFormJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Workflow::Form

  class << self
    def collect_file_ids_was_for_save(item)
      return []
    end

    def collect_file_ids_for_save(item)
      return []
    end
  end

  private

  def index_item_id
    "#{index_type}-workflow-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
    end
  end

  def convert_to_doc
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = item_url

    doc[:name] = item.name
    doc[:text] = item_text
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

    [ "#{index_type}-workflow-#{item.id}", doc ]
  end

  def item_text
    texts = []
    texts << item.memo
    texts += collect_form_text if item.respond_to?(:columns)
    texts.select(&:present?)
  end

  def item_url
    url_helpers.gws_workflow_form_path(site: site, id: item)
  end

  def collect_form_text
    texts = []
    item.columns.each do |column|
      texts << column.to_es
    end
    texts.compact
  end
end
