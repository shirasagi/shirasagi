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
      each_item do |item|
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end

      if @recursive
        criteria = Gws::Circular::Comment.site(site).without_deleted
        all_comment_ids = criteria.in(post_id: @ids).pluck(:id)
        each_item(criteria: criteria, ids: all_comment_ids) do |comment|
          y << self.class.convert_to_doc(self.site, comment.post, comment)
        end
      end
    end
  end
end
