module Gws::Elasticsearch::Indexer::BoardBase
  extend ActiveSupport::Concern
  include Gws::Elasticsearch::Indexer::Base

  module ClassMethods
    def convert_to_doc(cur_site, topic, post)
      doc = {}
      doc[:url] = path(site: cur_site, mode: '-', category: '-', id: topic, anchor: "post-#{post.id}")
      doc[:name] = post.name
      doc[:mode] = post.try(:mode)
      doc[:text] = post.text
      doc[:categories] = topic.categories.pluck(:name)

      doc[:release_date] = topic.release_date.try(:iso8601) if topic.respond_to?(:release_date)
      doc[:close_date] = topic.close_date.try(:iso8601) if topic.respond_to?(:close_date)
      doc[:released] = topic.released.try(:iso8601) if topic.respond_to?(:released)
      doc[:state] = post.try(:state) || 'public'

      doc[:user_name] = post.contributor_name.presence if topic.respond_to?(:contributor_name)
      doc[:user_name] ||= post.user_long_name
      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)
      doc[:permission_level] = post.permission_level

      doc[:member_ids] = topic.members.pluck(:id) if topic.respond_to?(:members)
      doc[:member_custom_group_ids] = topic.member_custom_groups.pluck(:id) if topic.respond_to?(:member_custom_groups)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id) if topic.respond_to?(:readable_groups)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id) if topic.respond_to?(:readable_custom_groups)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id) if topic.respond_to?(:readable_members)

      doc[:updated] = post.updated.try(:iso8601)
      doc[:created] = post.created.try(:iso8601)

      [ "post-#{post.id}", doc ]
    end

    def convert_file_to_doc(cur_site, topic, post, file)
      doc = {}
      doc[:url] = path(site: cur_site, mode: '-', category: '-', id: topic, anchor: "file-#{file.id}")
      doc[:name] = file.name
      doc[:categories] = topic.categories.pluck(:name)
      doc[:data] = Base64.strict_encode64(::File.binread(file.path))
      doc[:file] = {}
      doc[:file][:extname] = file.extname.upcase
      doc[:file][:size] = file.size

      doc[:release_date] = topic.release_date.try(:iso8601) if topic.respond_to?(:release_date)
      doc[:close_date] = topic.close_date.try(:iso8601) if topic.respond_to?(:close_date)
      doc[:released] = topic.released.try(:iso8601) if topic.respond_to?(:released)
      doc[:state] = post.try(:state) || 'public'

      doc[:group_ids] = post.groups.pluck(:id)
      doc[:custom_group_ids] = post.custom_groups.pluck(:id)
      doc[:user_ids] = post.users.pluck(:id)
      doc[:permission_level] = post.permission_level

      doc[:member_ids] = topic.members.pluck(:id) if topic.respond_to?(:members)
      doc[:member_custom_group_ids] = topic.member_custom_groups.pluck(:id) if topic.respond_to?(:member_custom_groups)

      doc[:readable_group_ids] = topic.readable_groups.pluck(:id) if topic.respond_to?(:readable_groups)
      doc[:readable_custom_group_ids] = topic.readable_custom_groups.pluck(:id) if topic.respond_to?(:readable_custom_groups)
      doc[:readable_member_ids] = topic.readable_members.pluck(:id) if topic.respond_to?(:readable_members)

      doc[:updated] = file.updated.try(:iso8601)
      doc[:created] = file.created.try(:iso8601)

      [ "file-#{file.id}", doc ]
    end
  end
end
