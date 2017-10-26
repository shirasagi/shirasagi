module Gws::Elasticsearch::Indexer::BoardBase
  extend ActiveSupport::Concern
  include Gws::Elasticsearch::Indexer::Base

  module ClassMethods
    def around_save(item)
      site = item.site
      before_file_ids = [ item.file_ids_was ].flatten.compact

      ret = yield

      after_file_ids = [ item.file_ids ].flatten.compact
      remove_file_ids = before_file_ids - after_file_ids

      if site.elasticsearch_enabled?
        job_params = {
          action: 'index', id: item.id.to_s, remove_file_ids: remove_file_ids.map(&:to_s)
        }
        job = self.bind(site_id: site)
        job.perform_later(job_params)
      end
      ret
    end

    def around_destroy(item)
      site = item.site
      id = item.id
      file_ids = [ item.file_ids ].flatten.compact

      ret = yield
      if site.elasticsearch_enabled?
        job_params = {
          action: 'delete', id: id.to_s, remove_file_ids: file_ids.map(&:to_s)
        }
        job = self.bind(site_id: site)
        job.perform_later(job_params)
      end
      ret
    end

    def convert_to_doc(cur_site, topic, post)
      doc = {}
      doc[:url] = url_helpers.gws_board_topic_path(site: cur_site, id: topic, anchor: "post-#{post.id}")
      doc[:name] = post.name
      doc[:mode] = post.mode
      doc[:text] = post.text
      doc[:categories] = topic.categories.pluck(:name)

      doc[:release_date] = topic.release_date.try(:iso8601) if topic.respond_to?(:release_date)
      doc[:close_date] = topic.close_date.try(:iso8601) if topic.respond_to?(:close_date)
      doc[:released] = topic.released.try(:iso8601) if topic.respond_to?(:released)
      doc[:state] = post.state

      doc[:user_name] = post.contributor_name.presence if topic.respond_to?(:contributor_name)
      doc[:user_name] ||= post.user_long_name
      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id)

      doc[:updated] = post.updated.try(:iso8601)
      doc[:created] = post.created.try(:iso8601)

      [ "post-#{post.id}", doc ]
    end

    def convert_file_to_doc(cur_site, topic, post, file)
      doc = {}
      doc[:url] = url_helpers.gws_board_topic_path(site: cur_site, id: topic, anchor: "file-#{file.id}")
      doc[:name] = file.name
      doc[:categories] = topic.categories.pluck(:name)
      doc[:data] = Base64.strict_encode64(::File.binread(file.path))
      doc[:file] = {}
      doc[:file][:extname] = file.extname.upcase
      doc[:file][:size] = file.size

      doc[:release_date] = topic.release_date.try(:iso8601)
      doc[:close_date] = topic.close_date.try(:iso8601)
      doc[:released] = topic.released.try(:iso8601)
      doc[:state] = post.state

      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id)

      doc[:updated] = file.updated.try(:iso8601)
      doc[:created] = file.created.try(:iso8601)

      [ "file-#{file.id}", doc ]
    end
  end
end
