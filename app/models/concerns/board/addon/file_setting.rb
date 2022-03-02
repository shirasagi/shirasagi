module Board::Addon
  module FileSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :cur_date

    included do
      field :file_limit, type: Integer, default: 0
      field :file_size_limit, type: Integer, default: (2 * 1024 * 1024)
      field :file_ext_limit, type: SS::Extensions::Words, default: ""
      field :file_scan, type: String, default: "disabled"

      permit_params :file_limit, :file_size_limit, :file_ext_limit, :file_scan
    end

    def allow_file_post?
      file_limit != 0
    end

    def file_scan_enabled?
      file_scan == "enabled"
    end

    def file_ext_limit
      file_ext_limit = self[:file_ext_limit] || []
      SS::Extensions::Words.new(file_ext_limit.map(&:downcase))
    end

    def file_limit_options
      %w(none 1n 2n 3n).collect.with_index do |v, i|
        label = I18n.t("board.options.file_limit.#{v}")
        label += I18n.t("board.cannot_use") if v != "none" && SS::Lgwan.enabled?
        [ label, i ]
      end
    end

    def file_size_limit_options
      [
        [I18n.t('board.options.file_size_limit.2MB'), 2 * 1024 * 1024],
        [I18n.t('board.options.file_size_limit.5MB'), 5 * 1024 * 1024],
        [I18n.t('board.options.file_size_limit.10MB'), 10 * 1024 * 1024],
        [I18n.t('board.options.file_size_limit.20MB'), 20 * 1024 * 1024],
        [I18n.t('board.options.file_size_limit.100MB'), 100 * 1024 * 1024],
        [I18n.t('board.options.file_size_limit.none'), 0],
      ]
    end

    def file_scan_options
      [
        [I18n.t('board.options.file_scan.disabled'), 'disabled'],
        [I18n.t('board.options.file_scan.enabled'), 'enabled'],
      ]
    end

    def mode_options
      [
        [I18n.t('board.options.mode.thread'), 'thread'],
        [I18n.t('board.options.mode.tree'), 'tree']
      ]
    end
  end
end
