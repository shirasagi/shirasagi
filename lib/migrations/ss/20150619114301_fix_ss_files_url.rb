class SS::Migration20150619114301
  include SS::Migration::Base

  depends_on "20150521192401"

  def change
    file_ids = SS::File.pluck(:id)
    file_ids.each do |id|
      item = SS::File.find(id) rescue nil
      next unless item

      begin
        if SS::FilenameUtils::NON_ASCII_RE.match?(item.filename)
          item.name = SS::FilenameUtils.convert_to_url_safe_japanese(item.filename) if item.name.blank? && item.filename.present?
          item.filename = SS::FilenameUtils.convert(SS::FilenameUtils.normalize(item.filename), id: item.id)
          unless item.save
            Rails.logger.fatal("ss_file save failed #{id}: #{item.errors.full_messages}")
          end
        end
      rescue => e
        Rails.logger.debug { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end

    Cms::Page.all.each { |item| replace_fs_urls(item) }
    Cms::Node.all.each { |item| replace_fs_urls(item) }
    Cms::Layout.all.each { |item| replace_fs_urls(item) }
    Cms::Part.all.each { |item| replace_fs_urls(item) }
  end

  def replace_fs_urls(item)
    if item.respond_to?(:html) && item.html.present?
      item.set(html: gsub_urls(item.html))
    end

    if item.respond_to?(:upper_html) && item.upper_html.present?
      item.set(upper_html: gsub_urls(item.upper_html))
    end

    if item.respond_to?(:loop_html) && item.loop_html.present?
      item.set(loop_html: gsub_urls(item.loop_html))
    end

    if item.respond_to?(:lower_html) && item.lower_html.present?
      item.set(lower_html: gsub_urls(item.lower_html))
    end
  end

  def gsub_urls(html)
    html.gsub(%r{(="/fs/)(\d+)(/[^/]+\.[\w\-.]+")}) do
      head = $1
      id   = $2
      tail = $3
      url  = SS::File.find(id.to_i).url rescue nil

      if url
        "=\"#{url}\""
      else
        "#{head}#{id.chars.join("/")}/_#{tail}"
      end
    end
  end
end
