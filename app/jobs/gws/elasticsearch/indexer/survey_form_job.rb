class Gws::Elasticsearch::Indexer::SurveyFormJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Survey::Form

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
    "#{index_type}-survey-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
    end
  end

  def convert_to_doc
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = url_helpers.gws_survey_editable_path(site: site, folder_id: "-", category_id: "-", id: item)
    doc[:name] = item.name
    doc[:text] = item_text
    doc[:categories] = item_categories

    doc[:release_date] = item_release_date
    doc[:close_date] = item_close_date
    #doc[:released] = item_released
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

    [ "#{index_type}-survey-#{item.id}", doc ]
  end

  def item_text
    texts = []
    texts << item.description
    texts << item.memo
    texts += collect_form_text if item.respond_to?(:columns)
    texts.select(&:present?)
  end

  def collect_form_text
    texts = []
    item.columns.each do |column|
      texts << column.to_es
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

  #def item_released
  #  item.released.try(:iso8601) if item.respond_to?(:released)
  #end
end
