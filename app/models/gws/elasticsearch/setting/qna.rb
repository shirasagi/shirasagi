class Gws::Elasticsearch::Setting::Qna
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Qna::Topic
end
