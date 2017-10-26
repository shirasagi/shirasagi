class Gws::Elasticsearch::Setting::Memo
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Memo::Message
end
