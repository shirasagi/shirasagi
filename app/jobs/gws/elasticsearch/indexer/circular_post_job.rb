class Gws::Elasticsearch::Indexer::CircularPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Circular::Post

  class << self
    def path(*args)
      url_helpers.gws_circular_topic_path(*args)
    end
  end

  def enum_es_docs
    topic = Gws::Circular::Topic.find(item.topic_id)

    Enumerator.new do |y|
      y << self.class.convert_to_doc(self.site, topic, item)
      if item.respond_to?(:files)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, topic, item, file)
        end
      end
    end
  end
end

