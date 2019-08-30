module Gws::Share::DescendantsFileInfo
  extend ActiveSupport::Concern
  extend SS::Translation
  include ActiveSupport::NumberHelper

  included do
    field :descendants_files_count, type: Integer, default: 0
    field :descendants_total_file_size, type: Integer, default: 0

    validate :validate_attached_file_size
    #after_save_files :set_file_info

    after_save :update_folder_descendants_file_info
    #after_destroy_files :update_folder_descendants_file_info
  end

  def total_file_size
    return @total_file_size if @total_file_size

    @total_file_size = files.compact.map(&:size).inject(:+) || 0
  end

  # def files_count
  #   return @files_count if @files_count
  #
  #   @files_count = files.active.compact.length || 0
  # end

  # def readable_active_files_count(user, site)
  #   files.readable(user, site: site).active.count
  # end

  # def readable_deleted_files_count(user, site)
  #   files.readable(user, site: site).deleted.count
  # end

  # def update_folder_descendants_file_info
  #   path = nil
  #   name.split("/").each do |n|
  #     path = path ? (path + "/" + n) : n
  #     folder = Gws::Share::Folder.site(site).where(name: path).first
  #     next unless folder
  #
  #     descendants_folder_ids = Gws::Share::Folder.site(site).where(name: /^#{::Regexp.escape(folder.name)}\//).pluck(:id)
  #     descendants_folder_ids << folder.id
  #     descendants_files = Gws::Share::File.site(site).in(folder_id: descendants_folder_ids)
  #
  #     folder.set(
  #       descendants_files_count: descendants_files.count,
  #       descendants_total_file_size: descendants_files.pluck(:size).sum
  #     )
  #   end
  # end
  def update_folder_descendants_file_info
    files_count = files.all.count
    total_file_size = files.all.pluck(:size).sum || 0

    children_info = children.pluck(:descendants_files_count, :descendants_total_file_size)
    files_count, total_file_size = children_info.each_with_object([ files_count, total_file_size ]) do |item, memo|
      memo[0] += item[0] if item[0].present?
      memo[1] += item[1] if item[1].present?
      memo
    end

    cur_files_count = self.descendants_files_count || 0
    cur_total_file_size = self.descendants_total_file_size || 0

    delta_files_count = files_count - cur_files_count
    delta_total_file_size = total_file_size - cur_total_file_size
    return if delta_files_count == 0 && delta_total_file_size == 0

    inc_operand = {
      descendants_files_count: delta_files_count,
      descendants_total_file_size: delta_total_file_size
    }
    self.inc(inc_operand)
    parents.inc(inc_operand)
  end

  private

  def validate_attached_file_size
    return if self.attributes["controller"] == "gws/share/folders"

    if (limit = (self.share_max_file_size || 0)) > 0
      size = files.compact.map(&:size).max || 0
      if size > limit
        errors.add(
          :base,
          :file_size_exceeds_folder_limit,
          size: number_to_human_size(size),
          limit: number_to_human_size(limit))
      end
    end
  end

  # def folder_file_info(folder)
  #   sizes = folder.files.compact.map(&:size) || []
  #   sizes.compact!
  #
  #   [ sizes.length, sizes.inject(:+) || 0 ]
  # end

  # def set_file_info
  #   files_count, total_file_size = folder_file_info(self)
  #   self.descendants_files_count = files_count
  #   self.descendants_total_file_size = total_file_size
  # end
end

