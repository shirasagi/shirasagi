class Gws::Elasticsearch::Indexer::DiscussionTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::DiscussionBase

  self.model = Gws::Discussion::Topic

  def enum_es_docs
    Enumerator.new do |y|
      topic_criteria = Gws::Discussion::Topic.site(site).without_deleted.exists(forum_id: true)
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
