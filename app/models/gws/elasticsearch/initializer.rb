module Gws::Elasticsearch
  class Initializer
    Gws::Role.permission :use_gws_elasticsearch, module_name: 'gws/elasticsearch'

    Gws.module_usable :elasticsearch do |site, user|
      Gws::Elasticsearch.allowed?(:use, user, site: site)
    end
  end
end
