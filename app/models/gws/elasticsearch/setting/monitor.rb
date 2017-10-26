class Gws::Elasticsearch::Setting::Monitor
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Monitor::Topic
end
