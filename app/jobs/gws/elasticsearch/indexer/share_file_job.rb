class Gws::Elasticsearch::Indexer::ShareFileJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  self.model = Gws::Share::File

  private

  def index_type
    'gws_share_files'
  end

  def index_item_id
    "file-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      doc = {}
      doc[:url] = item_path
      doc[:name] = item.name
      doc[:categories] = item.categories.pluck(:name)
      doc[:data] = Base64.strict_encode64(::File.binread(item.path))
      doc[:file] = {}
      doc[:file][:extname] = item.extname.upcase
      doc[:file][:size] = item.size

      # doc[:release_date] = topic.release_date.try(:iso8601)
      # doc[:close_date] = topic.close_date.try(:iso8601)
      # doc[:released] = topic.released.try(:iso8601)
      # doc[:state] = post.state
      doc[:state] = 'public'

      doc[:user_name] = item.user.long_name if item.user.present?
      doc[:group_ids] = item.groups.pluck(:id)
      doc[:custom_group_ids] = item.custom_groups.pluck(:id)
      doc[:user_ids] = item.users.pluck(:id)
      doc[:permission_level] = item.permission_level

      doc[:readable_group_ids] = item.readable_groups.pluck(:id)
      doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
      doc[:readable_member_ids] = item.readable_members.pluck(:id)

      doc[:updated] = item.updated.try(:iso8601)
      doc[:created] = item.created.try(:iso8601)

      y << [ "file-#{item.id}", doc ]
    end
  end

  def item_path
    if item.folder.present?
      url_helpers.gws_share_folder_file_path(site: self.site, folder: item.folder, id: item)
    else
      url_helpers.gws_share_file_path(site: self.site, id: item)
    end
  end
end
