class Gws::Elasticsearch::Setting::Board
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Board::Topic
end
