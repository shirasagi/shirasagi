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
      y << self.class.convert_to_doc(self.site, item, item)
      item.files.each do |file|
        y << self.class.convert_file_to_doc(self.site, item, item, file)
      end
    end
  end
end

