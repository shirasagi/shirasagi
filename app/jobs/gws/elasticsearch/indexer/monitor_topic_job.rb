class Gws::Elasticsearch::Indexer::MonitorTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::MonitorBase

  self.model = Gws::Monitor::Topic

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        puts item.name
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end

      if @original_id == :all
        all_topic_ids = self.class.model.site(site).without_deleted.pluck(:id)
        criteria = Gws::Monitor::Post.site(site).without_deleted
        all_post_ids = criteria.in(topic_id: all_topic_ids).pluck(:id)
        each_item(criteria: criteria, ids: all_post_ids) do |post|
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
