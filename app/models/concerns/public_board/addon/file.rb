module PublicBoard::Addon
  module File
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_files
      embeds_ids :files, class_name: "SS::File"

      permit_params in_files: []
      permit_params file_ids: []

      validate :validate_in_files, if: -> { in_files.present? }

      before_save :save_in_files, if: -> { in_files.present? }
      before_save :save_files
      after_destroy :destroy_files
    end

    def validate_in_files
      if node.file_limit < in_files.size
        errors.add :base, I18n.t("public_board.errors.too_many_files", limit: node.file_limit)
        return
      end

      in_files.each do |file|
        item = PublicBoard::File.new(site_id: site_id, state: "public")
        item.in_file = file
        item.name = file.original_filename
        ext_limit = node.file_ext_limit

        if !item.valid?
          errors.add :base, "#{item.name}#{I18n.t("errors.messages.invalid_file_type")}"
        end

        if node.file_size_limit < file.size
          errors.add :base, I18n.t(
            "errors.messages.too_large_file",
            filename: item.name,
            size: number_to_human_size(file.size),
            limit: number_to_human_size(node.file_size_limit))
        end

        if ext_limit.present? && !ext_limit.include?(item.extname.downcase)
          errors.add :base, "#{item.name}#{I18n.t("errors.messages.invalid_file_type")}"
        end
      end
      return unless errors.empty?

      if node.file_scan_enabled?
        in_files.each do |file|
          begin
            if !SS::FileScanner.scan(file)
              errors.add :base, "#{file.original_filename}#{I18n.t("errors.messages.invalid_file_type")}"
              return
            end
          rescue => e
            errors.add :base, I18n.t("errors.messages.file_scan_exception")
            return
          end
        end
      end
    end

    def save_in_files
      add_ids = []
      in_files.each do |file|
        item = PublicBoard::File.new(site_id: site_id, state: "public")
        item.in_file = file
        item.name = file.original_filename
        add_ids << item.id if item.save
      end
      self.file_ids = add_ids
    end

    def save_files
      return true unless file_ids_changed?

      add_ids = file_ids - file_ids_was.to_a

      ids = []
      files.each do |file|
        if add_ids.include?(file.id)
          # ignore @cur_user
          file.update_attributes(site_id: site_id, model: model_name.i18n_key, state: "public")
        end
        ids << file.id
      end
      self.file_ids = ids

      del_ids = file_ids_was.to_a - ids
      del_ids.each do |id|
        file = SS::File.where(id: id).first
        file.destroy if file
      end
    end

    def destroy_files
      files.destroy_all
    end

    def number_to_human_size(size)
      ApplicationController.helpers.number_to_human_size(size)
    end
  end
end
