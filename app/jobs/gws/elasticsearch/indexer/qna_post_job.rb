class Gws::Elasticsearch::Indexer::QnaPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Qna::Post

  class << self
    def path(*args)
      url_helpers.gws_qna_topic_path(*args)
    end
  end

  def enum_es_docs
    Enumerator.new do |y|
      each_item do |item|
        topic = Gws::Qna::Topic.find(item.topic_id)

        y << self.class.convert_to_doc(self.site, topic, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, topic, item, file)
        end
      end
    end
  end
end
