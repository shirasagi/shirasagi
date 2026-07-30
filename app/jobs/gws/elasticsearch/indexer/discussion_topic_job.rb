class Gws::Elasticsearch::Indexer::DiscussionTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Discussion::Topic

  class << self
    def convert_to_doc(cur_site, topic, post)
      doc = {}
      doc[:collection_name] = model.collection_name
      doc[:url] = path(site: cur_site, mode: '-', forum_id: topic.forum, topic_id: topic, anchor: "comment-#{post.id}")
      doc[:name] = post.name
      doc[:mode] = post.try(:mode)
      doc[:text] = post.text

      doc[:release_date] = topic.release_date.try(:iso8601) if topic.respond_to?(:release_date)
      doc[:close_date] = topic.close_date.try(:iso8601) if topic.respond_to?(:close_date)
      doc[:released] = topic.released.try(:iso8601) if topic.respond_to?(:released)
      doc[:state] = post.try(:state) || 'public'

      doc[:user_name] = post.contributor_name.presence if topic.respond_to?(:contributor_name)
      doc[:user_name] ||= post.user_long_name
      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)

      doc[:member_ids] = topic.members.pluck(:id) if topic.respond_to?(:members)
      doc[:member_group_ids] = topic.member_groups.pluck(:id) if topic.respond_to?(:member_groups)
      doc[:member_custom_group_ids] = topic.member_custom_groups.pluck(:id) if topic.respond_to?(:member_custom_groups)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id) if topic.respond_to?(:readable_groups)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id) if topic.respond_to?(:readable_custom_groups)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id) if topic.respond_to?(:readable_members)

      doc[:updated] = post.updated.try(:iso8601)
      doc[:created] = post.created.try(:iso8601)

      [ "#{model.collection_name}-topic-#{post.id}", doc ]
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

      doc[:updated] = file.updated.try(:iso8601)
      doc[:created] = file.created.try(:iso8601)

      [ "file-#{file.id}", doc ]
    end

    def path(*args)
      url_helpers.gws_discussion_forum_thread_comments_path(*args)
    end
  end

  def enum_es_docs
    Enumerator.new do |y|
      topic_criteria = Gws::Discussion::Topic.site(site).without_deleted
      each_item(criteria: topic_criteria) do |item|
        puts item.name
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end

      if @original_id == :all
        all_topic_ids = topic_criteria.pluck(:id)
        post_criteria = Gws::Discussion::Post.site(site).without_deleted
        post_criteria = post_criteria.in(topic_id: all_topic_ids)
        each_item(criteria: post_criteria) do |post|
          puts post.name
          topic = Gws::Discussion::Topic.find(post.topic_id)

          y << self.class.convert_to_doc(self.site, topic, post)
          post.files.each do |file|
            y << self.class.convert_file_to_doc(self.site, topic, post, file)
          end
        end
      end
    end
  end
end
