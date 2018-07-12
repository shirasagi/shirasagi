class Cms::AllContent
  class << self
    FIELDS_DEF = [
      %w(page_id to_page_id),
      %w(node_id to_node_id),
      %w(route),
      %w(name),
      %w(index_name),
      %w(filename),
      %w(url to_url),
      %w(layout to_layout),
      %w(keywords),
      %w(description),
      %w(summary_html),
      %w(conditions),
      %w(sort),
      %w(limit),
      %w(upper_html),
      %w(loop_setting_id to_loop_setting),
      %w(loop_html),
      %w(lower_html),
      %w(new_days),
      %w(category_ids to_categories),
      %w(files to_files),
      %w(file_urls to_file_urls),
      %w(use_map to_map_points),
      %w(group_names to_group_names),
      %w(released),
      %w(release_date),
      %w(close_date),
      %w(created),
      %w(updated),
      %w(status to_label),
      %w(file_size to_file_size),
    ].freeze

    def enum_csv(site)
      Enumerator.new do |y|
        y << encode_sjis(header.to_csv)
        (Cms::Page.site(site).all + Cms::Node.site(site).all).each do |content|
          content = content.becomes_with_route rescue content
          content.site ||= site
          y << encode_sjis(row(content).to_csv)
        end
      end
    end

    private

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def header
      FIELDS_DEF.map { |e| I18n.t("all_content.#{e[0]}") }
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

        val = I18n.l(val) if val.is_a?(Time) || val.is_a?(Date) || val.is_a?(DateTime)
        val
      end
    end

    def to_page_id(key, content)
      content.is_a?(Cms::Model::Page) ? content.id : nil
    end

    def to_node_id(key, content)
      content.is_a?(Cms::Model::Node) ? content.id : nil
    end

    def to_layout(key, content)
      content.layout.filename
    end

    def to_loop_setting(key, content)
      return nil if !content.respond_to?(:loop_setting_id)
      content.loop_setting.try(:name) || I18n.t("cms.input_directly")
    end

    def to_url(key, content)
      content.full_url
    end

    def to_categories(key, content)
      Category::Node::Base.where(:id.in => content.category_ids).
        pluck(:name, :filename).
        map { |name, filename| "#{filename}(#{name})" }.
        join("\n")
    end

    def to_files(key, content)
      content.files.map(&:name).join("\n")
    end

    def to_file_urls(key, content)
      content.files.map(&:url).join("\n")
    end

    def to_map_points(key, content)
      content.map_points.map { |point| point[:loc].join(",") }.join("\n")
    end

    def to_group_names(key, content)
      Cms::Group.where(:id.in => content.group_ids).pluck(:name).join(",")
    end

    def to_label(key, content)
      content.label(key)
    end

    def to_file_size(key, content)
      return nil unless File.exist?(content.path)

      size = File.stat(content.path).size
      return size unless content.respond_to?(:files)

      content.files.each do |file|
        if File.exist?(file.public_path)
          size += File.stat(file.public_path).size.to_i
        end
      end
      size
    end
  end
end

