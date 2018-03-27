module Gws::Elasticsearch::Indexer::MemoBase
  extend ActiveSupport::Concern
  include Gws::Elasticsearch::Indexer::Base

  REDIRECT = 'REDIRECT'.freeze

  module ClassMethods
    # Do not consider soft delete of Gws::Memo::Message; it's shared by multi members and controlled by "member_ids" and "path"
    def around_save(item)
      site = item.site
      before_file_ids = collect_file_ids_was_for_save(item)

      ret = yield
      return ret unless site.menu_elasticsearch_visible?

      after_file_ids = collect_file_ids_for_save(item)
      remove_file_ids = before_file_ids - after_file_ids

      #if item.deleted.present?
      #  # soft deleted
      #  job = self.bind(site_id: site)
      #  job.perform_later(action: 'delete', id: item.id.to_s, remove_file_ids: (before_file_ids | after_file_ids).map(&:to_s))
      #  return ret
      #end

      job = self.bind(site_id: site)
      job.perform_later(
          action: 'index', id: item.id.to_s, remove_file_ids: remove_file_ids.map(&:to_s)
      )

      ret
    end
  end
end
