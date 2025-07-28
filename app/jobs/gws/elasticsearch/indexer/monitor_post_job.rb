class Gws::Elasticsearch::Indexer::MonitorPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::MonitorBase

  self.model = Gws::Monitor::Post

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        topic = Gws::Monitor::Topic.find(item.topic_id)

        y << self.class.convert_to_doc(self.site, topic, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, topic, item, file)
        end
      end
    end
  end
end
