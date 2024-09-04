class Cms::MobileSizeChecker
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :html

  validate :validate_html

  private

  def validate_html
    validate_html_byte_size
    validate_html_img_size
  end

  def validate_html_byte_size
    limit_size = cur_site.mobile_size
    size = html.bytesize
    return if size <= limit_size

    message = I18n.t(
      'errors.messages.mobile_size_check_failed_to_size',
      mobile_size: limit_size.to_fs(:human_size), size: size.to_fs(:human_size)
    )
    errors.add :base, message
  end

  def validate_html_img_size
    limit_size = cur_site.mobile_size

    img_file_ids = collect_img_file_ids
    return if img_file_ids.blank?

    img_files = SS::File.in(id: img_file_ids).to_a
    return if img_files.blank?

    total_size = 0
    img_files.each do |file|
      thumb = file.thumb
      next unless thumb

      total_size += thumb.size
      next if thumb.size <= limit_size

      errors.add :base, I18n.t(
        "errors.messages.too_bigfile",
        filename: file.name,
        filesize: thumb.size.to_fs(:human_size),
        mobile_size: limit_size.to_fs(:human_size)
      )
    end
    if total_size > limit_size
      errors.add :base, I18n.t(
        "errors.messages.too_bigsize",
        total: total_size.to_fs(:human_size),
        mobile_size: limit_size.to_fs(:human_size)
      )
    end
  end

  def collect_img_file_ids
    img_ids = []

    base_url = normalize_url(cur_site.full_url)
    each_img_tag do |img_tag|
      src_attr = find_src_attr_and_normalize(img_tag, base_url)
      next if src_attr.blank? || !src_attr.start_with?("/fs/")
      next unless src_attr =~ /^\/fs\/(.+?)\/_\//

      str_id = $1
      str_id = str_id.delete("/")
      img_ids.push(str_id.to_i) if str_id.numeric?
    end

    img_ids.uniq
  end

  def normalize_url(url)
    if !url.end_with?("/")
      url += "/"
    end

    url
  end

  def each_img_tag(&block)
    html.scan(/<\s*img\s+.*?>/im, &block)
  end

  def find_src_attr_and_normalize(img_tag, base_url)
    return unless img_tag =~ /src=["'](.+?)["']/

    src_attr = $1
    if src_attr.start_with?(base_url)
      src_attr = src_attr.sub(base_url, "/")
    end
    src_attr
  end
end
