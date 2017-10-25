class Gws::Elasticsearch::Setting::All
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Board::Post.collection_name if Gws::Board::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types << Gws::Faq::Post.collection_name if Gws::Faq::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types << Gws::Qna::Post.collection_name if Gws::Qna::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types << Gws::Circular::Post.collection_name if Gws::Circular::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types << Gws::Monitor::Post.collection_name if Gws::Monitor::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types << 'gws_share_files' if Gws::Share::File.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
