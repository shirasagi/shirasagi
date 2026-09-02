module Gws::Elasticsearch::Indexer::DiscussionBase
  extend ActiveSupport::Concern
  include Gws::Elasticsearch::Indexer::Base

  module ClassMethods
    def convert_to_doc(cur_site, topic, post)
      doc = {}
      doc[:collection_name] = model.collection_name
      doc[:url] = path(site: cur_site, mode: '-', forum_id: topic.forum, topic_id: topic, anchor: "comment-#{post.id}")
      doc[:name] = post.name
      doc[:mode] = post.try(:mode)
      doc[:text] = post.text

      set_basic_attributes(doc, topic, post)

      doc[:updated] = post.updated.try(:iso8601)
      doc[:created] = post.created.try(:iso8601)

      [ "#{model.collection_name}-post-#{post.id}", doc ]
    end

    def convert_file_to_doc(cur_site, topic, post, file)
      doc = {}
      doc[:collection_name] = model.collection_name
      doc[:url] = path(site: cur_site, mode: '-', forum_id: topic.forum, topic_id: topic, anchor: "file-#{file.id}")
      doc[:name] = file.name
      doc[:data] = Base64.strict_encode64(::File.binread(file.path))
      doc[:file] = {}
      doc[:file][:extname] = file.extname.upcase
      doc[:file][:size] = file.size

      set_basic_attributes(doc, topic, post)

      doc[:updated] = file.updated.try(:iso8601)
      doc[:created] = file.created.try(:iso8601)

      [ "file-#{file.id}", doc ]
    end

    def set_basic_attributes(doc, topic, post)
      doc[:release_date] = topic.release_date.try(:iso8601) if topic.respond_to?(:release_date)
      doc[:close_date] = topic.close_date.try(:iso8601) if topic.respond_to?(:close_date)
      doc[:released] = topic.released.try(:iso8601) if topic.respond_to?(:released)
      doc[:state] = post.try(:state) || 'public'

      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)

      doc[:member_ids] = topic.members.pluck(:id) if topic.respond_to?(:members)
      doc[:member_custom_group_ids] = topic.member_custom_groups.pluck(:id) if topic.respond_to?(:member_custom_groups)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id) if topic.respond_to?(:readable_groups)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id) if topic.respond_to?(:readable_custom_groups)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id) if topic.respond_to?(:readable_members)
      doc
    end

    def path(*args)
      url_helpers.gws_discussion_forum_thread_comments_path(*args)
    end
  end
end
