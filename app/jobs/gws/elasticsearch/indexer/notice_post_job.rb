class Gws::Elasticsearch::Indexer::NoticePostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Notice::Post

  class << self
    def path(site:, mode:, category:, id:, anchor:)
      url_helpers.gws_notice_redirect_path(site: site, folder_id: mode, category_id: category, id: id, anchor: anchor)
    end
  end

  def enum_es_docs
    Enumerator.new do |y|
      post_criteria = Gws::Notice::Post.site(site).without_deleted
      each_item(criteria: post_criteria) do |item|
        puts item.name
        y << self.class.convert_to_doc(self.site, item, item)
        item.files.each do |file|
          y << self.class.convert_file_to_doc(self.site, item, item, file)
        end
      end
    end
  end
end
