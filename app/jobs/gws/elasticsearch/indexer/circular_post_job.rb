class Gws::Elasticsearch::Indexer::CircularPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Circular::Post

  class << self
    def path(*args)
      options = args.extract_options!
      options.delete(:mode)
      args << options
      url_helpers.gws_circular_post_path(*args)
    end
  end

  def enum_es_docs
    Enumerator.new do |y|
      post_criteria = Gws::Circular::Post.site(site).topic.without_deleted
      each_item(criteria: post_criteria) do |item|
        puts item.name
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end

      if @original_id == :all
        all_post_ids = post_criteria.pluck(:id)
        comment_criteria = Gws::Circular::Comment.site(site).without_deleted
        comment_criteria = comment_criteria.in(post_id: all_post_ids)
        each_item(criteria: comment_criteria) do |comment|
          puts comment.name
          y << self.class.convert_to_doc(self.site, comment.post, comment)
        end
      end
    end
  end
end
