module Gws::Board::DescendantsFileInfo
  extend ActiveSupport::Concern
  include ActiveSupport::NumberHelper

  included do
    field :descendants_files_count, type: Integer
    field :descendants_total_file_size, type: Integer

    validate :validate_attached_file_size

    # before_save :set_file_info, if: -> { topic_id.blank? }
    after_save_files :set_file_info, if: -> { topic_id.blank? }

    after_save :update_topic_descendants_file_info, if: -> { topic_id.present? }
    after_destroy_files :update_topic_descendants_file_info, if: -> { topic_id.present? }
  end

  private
    def validate_attached_file_size
      if (limit = (cur_site.board_file_size_per_post || 0)) > 0
        size = files.compact.map(&:size).max || 0
        if size > limit
          errors.add(
            :base,
            :file_size_exceeds_post_limit,
            size: number_to_human_size(size),
            limit: number_to_human_size(limit))
        end
      end

      if (limit = (cur_site.board_file_size_per_topic || 0)) > 0
        size = files.compact.map(&:size).inject(:+) || 0

        comments = self.class.topic_comments(topic || self).ne(_id: id)
        comment_files = comments.map(&:files).flatten
        size += comment_files.compact.map(&:size).inject(:+) || 0

        size += topic.files.compact.map(&:size).inject(:+) || 0 if topic.present?

        if size > limit
          errors.add(
            :base,
            :file_size_exceeds_topic_limit,
            size: number_to_human_size(size),
            limit: number_to_human_size(limit))
        end
      end
    end

    def topic_file_info(topic)
      sizes = topic.files.compact.map(&:size) || []

      comments = self.class.topic_comments(topic)
      comment_files = comments.map(&:files).flatten

      sizes += comment_files.compact.map(&:size) || []
      sizes.compact!

      [ sizes.length, sizes.inject(:+) || 0 ]
    end

    def set_file_info
      files_count, total_file_size = topic_file_info(self)
      self.descendants_files_count = files_count
      self.descendants_total_file_size = total_file_size
    end

    def update_topic_descendants_file_info
      return unless topic
      files_count, total_file_size = topic_file_info(topic)
      topic.set(
        descendants_files_count: files_count,
        descendants_total_file_size: total_file_size
      )
    end
end
