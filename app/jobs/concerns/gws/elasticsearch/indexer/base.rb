module Gws::Elasticsearch::Indexer::Base
  extend ActiveSupport::Concern

  module ClassMethods
    def callback
      self
    end

    def around_save(item)
      ret = yield
      if item.site.elasticsearch_enabled?
        job = self.bind(site_id: item.site)
        job.perform_later(action: 'index', id: item.id.to_s)
      end
      ret
    end

    def around_destroy(item)
      site = item.site
      id = item.id
      ret = yield
      if item.site.elasticsearch_enabled?
        job = self.bind(site_id: site)
        job.perform_later(action: 'delete', id: id.to_s)
      end
      ret
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end

  def perform(options)
    options = options.dup
    action = options.delete(:action)

    self.send(action, options)
  end

  private

  def url_helpers
    self.class.url_helpers
  end
end
