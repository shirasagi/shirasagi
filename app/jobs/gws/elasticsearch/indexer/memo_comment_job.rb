class Gws::Elasticsearch::Indexer::MemoCommentJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::Base
  include Gws::Elasticsearch::Indexer::MemoBase

  self.model = Gws::Memo::Comment

  private

  def index_type
    @index_type ||= Gws::Memo::Message.collection_name
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
    end
  end

  def convert_to_doc
    message = item.message

    doc = {}
    doc[:url] = url_helpers.gws_memo_message_path(site: site, folder: REDIRECT, id: message, anchor: "comment-#{item.id}")
    doc[:name] = message.subject
    doc[:mode] = message.format
    doc[:text] = item_text
    # doc[:categories] = item.categories.pluck(:name)

    # doc[:release_date] =
    # doc[:close_date] =
    doc[:released] = item.updated.try(:iso8601)
    doc[:state] = message.state

    doc[:user_name] = item.user_long_name
    # doc[:group_ids] = item.groups.pluck(:id)
    # doc[:custom_group_ids] = item.custom_groups.pluck(:id)
    doc[:user_ids] = [ item.user_id ]
    # doc[:permission_level] = item.permission_level

    # doc[:readable_group_ids] =
    # doc[:readable_custom_group_ids] =
    doc[:readable_member_ids] = message.members.pluck(:id) + [ message.user_id ]

    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ "comment-#{item.id}", doc ]
  end

  def item_text
    item.text
  end
end
