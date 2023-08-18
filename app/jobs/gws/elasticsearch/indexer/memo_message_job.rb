class Gws::Elasticsearch::Indexer::MemoMessageJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base
  include Gws::Elasticsearch::Indexer::MemoBase

  self.model = Gws::Memo::Message

  private

  def item
    @item ||= begin
      item = Gws::Memo::Message.find(@id)
      if item.list_message?
        item = item.to_list_message
      end
      item
    end
  end

  def index_item_id
    "#{index_type}-message-#{@id}"
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
      item.files.each { |file| y << convert_file_to_doc(file) }
    end
  end

  def convert_to_doc
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = url_helpers.gws_memo_message_path(site: site, folder: REDIRECT, id: item, anchor: "message-#{item.id}")
    doc[:name] = item.subject
    doc[:mode] = item.format
    doc[:text] = item_text
    # doc[:categories] = item.categories.pluck(:name)

    # doc[:release_date] =
    # doc[:close_date] =
    doc[:released] = item.send_date.try(:iso8601)
    doc[:state] = item.state

    if item.is_a?(Gws::Memo::ListMessage)
      doc[:user_name] = item.from_member_name
      doc[:group_ids] = item.list.groups.pluck(:id)
      doc[:custom_group_ids] = item.list.custom_groups.pluck(:id)
      doc[:user_ids] = item.list.users.pluck(:id)
      doc[:permission_level] = item.list.permission_level
    else
      doc[:user_name] = item.user_long_name
      # doc[:group_ids] = item.groups.pluck(:id)
      # doc[:custom_group_ids] = item.custom_groups.pluck(:id)
      doc[:user_ids] = [ item.user_id ] if item.readable?(item.user, site: site)
      # doc[:permission_level] = item.permission_level
    end

    # doc[:readable_group_ids] =
    # doc[:readable_custom_group_ids] =
    doc[:readable_member_ids] = item.members.pluck(:id)

    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ "#{index_type}-message-#{item.id}", doc ]
  end

  def convert_file_to_doc(file)
    doc = {}
    doc[:collection_name] = index_type
    doc[:url] = url_helpers.gws_memo_message_path(site: site, folder: REDIRECT, id: item, anchor: "file-#{file.id}")
    doc[:name] = file.name
    # doc[:categories] = item.categories.pluck(:name)
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size

    # doc[:release_date] = item.release_date.try(:iso8601)
    # doc[:close_date] = item.close_date.try(:iso8601)
    doc[:released] = item.send_date.try(:iso8601)
    doc[:state] = item.state

    if item.is_a?(Gws::Memo::ListMessage)
      doc[:user_name] = item.from_member_name
      doc[:group_ids] = item.list.groups.pluck(:id)
      doc[:custom_group_ids] = item.list.custom_groups.pluck(:id)
      doc[:user_ids] = item.list.users.pluck(:id)
      doc[:permission_level] = item.list.permission_level
    else
      # doc[:group_ids] = item.groups.pluck(:id)
      # doc[:custom_group_ids] = item.custom_groups.pluck(:id)
      doc[:user_ids] = [ item.user_id ] if item.readable?(item.user, site: site)
      # doc[:permission_level] = item.permission_level
    end

    # doc[:readable_group_ids] =
    # doc[:readable_custom_group_ids] =
    doc[:readable_member_ids] = item.members.pluck(:id)

    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def item_text
    if item.format == 'html'
      ApplicationController.helpers.sanitize(item.html.presence || '', tags: [])
    else
      item.text
    end
  end
end
