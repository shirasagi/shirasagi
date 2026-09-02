class Gws::Elasticsearch::Indexer::DiscussionPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::DiscussionBase

  self.model = Gws::Discussion::Post

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        topic = Gws::Discussion::Topic.find(item.topic_id)

        y << self.class.convert_to_doc(self.site, topic, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, topic, item, file)
        end
      end
    end
  end
end
