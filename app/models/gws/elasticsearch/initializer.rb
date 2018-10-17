module Gws::Elasticsearch
  class Initializer
    Gws::Role.permission :use_gws_elasticsearch, module_name: 'gws/elasticsearch'
  end
end
