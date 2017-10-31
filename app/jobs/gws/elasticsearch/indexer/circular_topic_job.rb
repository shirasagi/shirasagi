class Gws::Elasticsearch::Indexer::CircularTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Circular::Topic

  class << self
    def path(*args)
      url_helpers.gws_circular_topic_path(*args)
    end
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << self.class.convert_to_doc(self.site, item, item)
      item.files.each do |file|
        y << self.class.convert_file_to_doc(self.site, item, item, file)
      end
    end
  end
end

