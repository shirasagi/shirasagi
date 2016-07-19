class Rss::Author
  extend SS::Translation
  include SS::Document

  field :name, type: String
  field :email, type: String
  field :uri, type: String

  embedded_in :rss_author, polymorphic: true
end
