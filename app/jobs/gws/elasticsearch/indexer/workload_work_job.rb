# not used
class Gws::Elasticsearch::Indexer::WorkloadWorkJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Workload::Work

  private

  def index_type
    'gws_workload_works'
  end

  def index_item_id
    "#{index_type}-workload-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        @id = item.id.to_s
        @item = item

        y << convert_to_doc
        item.files.each do |file|
          y << convert_file_to_doc(file)
        end
      ensure
        @id = nil
        @item = nil
      end
    end
  end

  def convert_to_doc
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = url_helpers.gws_workload_admin_path(site: site, id: item)
    doc[:name] = item.name
    doc[:text] = item.text
    doc[:categories] = item.category ? [item.category.name] : []
    doc[:state] = item.state

    doc[:user_name] = item.user_long_name
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)

    doc[:member_ids] = item.members.pluck(:id)
    #doc[:member_custom_group_ids] = item.member_custom_groups.pluck(:id)

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ "#{index_type}-workload-#{item.id}", doc ]
  end

  def convert_file_to_doc(file)
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = url_helpers.gws_workload_admin_path(site: site, id: item, anchor: "file-#{file.id}")
    doc[:name] = file.name
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size
    doc[:state] = item.state

    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
    doc[:permission_level] = item.permission_level

    doc[:member_ids] = item.members.pluck(:id)
    #doc[:member_custom_group_ids] = item.member_custom_groups.pluck(:id)

    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)

    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end
end
