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
      each_item do |item|
        @id = item.id.to_s
        @item = item
        puts item.name

        y << convert_to_doc
      ensure
        @id = nil
        @item = nil
      end
    end
  end

  def convert_to_doc
    doc = { collection_name: index_type }
    Gws::Elasticsearch.mappings_keys.each do |key|
      if respond_to?("build_#{key}", true)
        send("build_#{key}", doc)
      end
    end

    [ "file-#{item.id}", doc ]
  end

  def item_path
    if item.folder.present?
      url_helpers.gws_share_folder_file_path(site: self.site, folder: item.folder, id: item)
    else
      url_helpers.gws_share_file_path(site: self.site, id: item)
    end
  end

  def build_url(doc)
    doc[:url] = item_path
  end

  def build_name(doc)
    doc[:name] = item.name
  end

  def build_categories(doc)
    doc[:categories] = item.categories.pluck(:name)
  end

  def build_file(doc)
    doc[:file] = {
      extname: item.extname.upcase,
      size: item.size
    }
    doc[:data] = Base64.strict_encode64(::File.binread(item.path))
  end

  def build_state(doc)
    # doc[:release_date] = topic.release_date.try(:iso8601)
    # doc[:close_date] = topic.close_date.try(:iso8601)
    # doc[:released] = topic.released.try(:iso8601)
    # doc[:state] = post.state
    doc[:state] = 'public'
  end

  def build_user_name(doc)
    doc[:user_name] = item.user.long_name if item.user.present?
  end

  def build_user_ids(doc)
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = item.users.pluck(:id)
  end

  def build_readable_member_ids(doc)
    doc[:readable_group_ids] = item.readable_groups.pluck(:id)
    doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
    doc[:readable_member_ids] = item.readable_members.pluck(:id)
  end

  def build_updated(doc)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)
  end
end
