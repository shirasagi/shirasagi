class Gws::Elasticsearch::Indexer::MonitorTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::MonitorBase

  self.model = Gws::Monitor::Topic

  def enum_es_docs
    Enumerator.new do |y|
      topic_criteria = Gws::Monitor::Topic.site(site).topic.without_deleted
      each_item(criteria: topic_criteria) do |item|
        puts item.name
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end

      if @original_id == :all
        all_topic_ids = topic_criteria.pluck(:id)
        post_criteria = Gws::Monitor::Post.site(site).without_deleted
        post_criteria = post_criteria.in(topic_id: all_topic_ids)
        each_item(criteria: post_criteria) do |post|
          puts post.name
          topic = Gws::Monitor::Topic.find(post.topic_id)

          y << self.class.convert_to_doc(self.site, topic, post)
          post.files.each do |file|
            y << self.class.convert_file_to_doc(self.site, topic, post, file)
          end
        end
      end
    end
  end
end
