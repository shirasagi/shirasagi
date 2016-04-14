module Gws::Board::DescendantsFileInfo
  extend ActiveSupport::Concern

  included do
    field :descendants_files_count, type: Integer
    field :descendants_total_file_size, type: Integer

    validate :validate_attached_file_size

    # before_save :set_file_info, if: -> { topic_id.blank? }
    after_save :update_topic_descendants_file_info, if: -> { topic_id.present? }
  end

  # override Gws::Addon::File#save_files
  def save_files
    super
    set_file_info if topic_id.blank?
  end

  private
    def validate_attached_file_size
      if limit = cur_site.board_file_size_per_post
        size = files.compact.map(&:size).max || 0
        if size > limit
          errors.add :base, :attached_file_too_large, size: size, limit: limit
        end
      end

      if limit = cur_site.board_file_size_per_topic
        size = files.compact.map(&:size).inject(:+) || 0

        comments = self.class.topic_comments(topic || self).ne(_id: id)
        comment_files = comments.map(&:files).flatten
        size += comment_files.compact.map(&:size).inject(:+) || 0

        size += topic.files.compact.map(&:size).inject(:+) || 0 if topic.present?

        if size > limit
          errors.add :base, :attached_file_too_large, size: size, limit: limit
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
          descendants_total_file_size: total_file_size,
      )
    end
end
