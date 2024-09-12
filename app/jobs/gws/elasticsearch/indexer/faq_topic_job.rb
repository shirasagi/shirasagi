class Gws::Elasticsearch::Indexer::FaqTopicJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Faq::Topic

  class << self
    def path(*args)
      url_helpers.gws_faq_topic_path(*args)
    end
  end

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
        criteria = Gws::Faq::Post.site(site).without_deleted
        all_post_ids = criteria.in(topic_id: all_topic_ids).pluck(:id)
        each_item(criteria: criteria, ids: all_post_ids) do |post|
          puts post.name
          topic = Gws::Faq::Topic.find(post.topic_id)

          y << self.class.convert_to_doc(self.site, topic, post)
          post.files.each do |file|
            y << self.class.convert_file_to_doc(self.site, topic, post, file)
          end
        end
      end
    end
  end
end
