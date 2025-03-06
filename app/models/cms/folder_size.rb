class Cms::FolderSize
  # check reverse mapping in `app/jobs/cms/folder_csvs_import_job.rb`
  FIELDS_DEF = begin
    fields = [
      %w(name),
      %w(index_name),
      %w(filename),
      %w(layout to_layout),
      %w(depth),
      %w(order),
      %w(keywords),
      %w(description),
      %w(summary_html),
      %w(status to_label),
      %w(released),
      %w(group_names to_group_names)
    ]
    fields << %w(size to_size)
    fields
  end.freeze

  class << self
    def enum_csv(site)
      Enumerator.new do |y|
        y << encode_sjis(header.to_csv)
        Cms::Node.site(site).each do |content|
          y << encode_sjis(row(content).to_csv)
        end
      end
    end

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def header
      FIELDS_DEF.map { |e| I18n.t("folder_size.#{e[0]}") }
    end

    def valid_header?(path)
      path = path.path if path.respond_to?(:path)

      match_count = 0
      SS::Csv.foreach_row(path, headers: true) do |row|
        FIELDS_DEF.each do |e|
          if row.key?(I18n.t("folder_size.#{e[0]}"))
            match_count += 1
          end
        end
        break
      end

      # if 80% of headers are matched, we considered it is valid
      match_count >= FIELDS_DEF.length * 0.8
    rescue => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      false
    end

    def row(content)
      FIELDS_DEF.map do |e|
        begin
          if e.length <= 1
            val = content.send(e[0])
          else
            val = send(e[1], e[0], content)
          end
        rescue => e
          val = nil
        end

        val = I18n.l(val) if val.respond_to?(:strftime)
        val
      end
    end

    def to_layout(key, content)
      return nil if content.layout.blank?
      content.layout.filename
    end

    def to_group_names(key, content)
      Cms::Group.site(content.site).where(:id.in => content.group_ids).pluck(:name).join(",")
    end

    def to_label(key, content)
      content.label(key)
    end

    def to_size(key, content)
      Cms::Page.site(content.site).where(filename: /^#{::Regexp.escape(content.filename)}\//).sum(:size)
    end
  end
end
