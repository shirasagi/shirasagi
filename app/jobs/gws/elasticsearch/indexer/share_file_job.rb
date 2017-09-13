class Gws::Elasticsearch::Indexer::ShareFileJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base

  def index(options)
    @id = options[:id]

    es_client = site.elasticsearch_client
    return unless es_client

    enum_es_docs.each do |id, doc|
      es_client.index(index: index_name, type: index_type, id: id, body: doc, pipeline: 'attachment')
    end
  end

  def delete(options)
    @id = options[:id]

    es_client = site.elasticsearch_client
    return unless es_client

    es_client.delete(index: index_name, type: index_type, id: "file-#{@id}")
  end

  private

  def item
    @item ||= Gws::Share::File.find(@id)
  end

  def index_name
    @index ||= "g#{site.id}"
  end

  def index_type
    'gws_share_files'
  end

  def enum_es_docs
    Enumerator.new do |y|
      doc = {}
      doc[:url] = url_helpers.gws_share_file_path(site: self.site, id: item)
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

      doc[:group_ids] = item.groups.pluck(:id)
      doc[:custom_group_ids] = item.custom_groups.pluck(:id)
      doc[:user_ids] = item.users.pluck(:id)

      doc[:readable_group_ids] = item.readable_groups.pluck(:id)
      doc[:readable_custom_group_ids] = item.readable_custom_groups.pluck(:id)
      doc[:readable_member_ids] = item.readable_members.pluck(:id)

      doc[:updated] = item.updated.try(:iso8601)
      doc[:created] = item.created.try(:iso8601)

      y << [ "file-#{item.id}", doc ]
    end
  end
end
