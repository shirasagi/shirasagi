class Gws::Elasticsearch::Setting::Faq
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Faq::Topic
end
