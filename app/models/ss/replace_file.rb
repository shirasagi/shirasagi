class SS::ReplaceFile
  include SS::Model::File
  include SS::Relation::Thumb
  include SS::Relation::FileBranch
  include SS::Relation::FileHistory
  include SS::Liquidization

  before_validation :set_source_instance

  # history_file
  before_save :save_history_file, if: -> { in_file.present? }
  before_save :save_file

  # thumbs
  after_save :destroy_thumbs, if: -> { in_file || resizing }
  after_save :save_thumbs, if: -> { disable_thumb.blank? && image? }

  # owner item
  after_save :update_owner_item

  private

  def set_source_instance
    @source = history_file_instance

    # restore clean attributes
    @source.id = id
    @source._id = id
    @source.filename = filename_was
    @source.name = name_was
    @source.size = size_was

    @source_url = @source.url
    @source_thumb_url = @source.thumb_url
  end

  # 拡張子が異なるときのみファイル名を変更する
  def set_filename
    self.filename = in_file.original_filename if in_file_extname != extname
    self.size = in_file.size
    self.content_type = ::SS::MimeType.find(in_file.original_filename, in_file.content_type)
  end

  def in_file_extname
    ::File.extname(in_file.original_filename).delete(".")
  end

  def save_history_file
    now = Time.zone.now
    source_attributes = @source.attributes.dup
    source_attributes["original_id"] = id
    source_attributes["created"] = now
    source_attributes["updated"] = now
    source_attributes["state"] = "closed"
    source_attributes.delete("_id")
    source_attributes.delete("id")

    @source.class.create_empty!(source_attributes) do |new_file|
      ::FileUtils.copy(self.path, new_file.path)
      new_file.disable_thumb = true
      new_file.save!
    end

    max_age = 50
    history_files.skip(max_age).destroy
  rescue => e
    Rails.logger.fatal("save_history_file failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def update_owner_item
    if owner_item && owner_item.class.include?(Cms::Model::Page)
      update_owner_page
    end
  rescue => e
    Rails.logger.fatal("update_owner_item failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def update_owner_page
    item = self.owner_item

    if item.respond_to?(:form) && item.form
      item.column_values.each do |column_value|
        if column_value.class == Cms::Column::Value::Free
          column_value.value = replace_html(column_value.value.to_s.dup)
          column_value.save!
        end
      end
    elsif item.respond_to?(:html) && item.html.present?
      item.html = replace_html(item.html.dup)
    end

    item.save!
  end

  def replace_html(html)
    helpers = ApplicationController.helpers

    humanized_name1 = @source.humanized_name
    humanized_name2 = "#{@source.filename} (#{@source.extname.upcase} #{number_to_human_size(@source.size)})"

    action_attach_src1 = helpers.link_to(humanized_name1, @source_url, class: "icon-#{@source.extname}")
    action_attach_src2 = helpers.link_to(humanized_name2, @source_url, class: "icon-#{@source.extname}")
    action_attach_dst = helpers.link_to(humanized_name, url, class: "icon-#{extname}")

    action_paste_src = helpers.image_tag(@source_url, alt: @source.name)
    action_paste_dst = helpers.image_tag(url, alt: name)

    action_thumb_src = helpers.image_tag(@source_thumb_url, alt: @source.name)
    action_thumb_dst = helpers.image_tag(thumb_url, alt: name)

    html.gsub!(action_attach_src1, action_attach_dst)
    html.gsub!(action_attach_src2, action_attach_dst)
    html.gsub!(action_thumb_src, action_thumb_dst)
    html.gsub!(action_paste_src, action_paste_dst)

    html.gsub!("=\"#{@source_url}\"", "=\"#{url}\"")
    html.gsub!("=\"#{@source_thumb_url}\"", "=\"#{thumb_url}\"")

    html
  end

  class << self
    def replaceable?(item, opts = {})
      user = opts[:user]
      site = opts[:site]
      node = opts[:node]

      if item.public?
        item.allowed?(:release, user, site: site, node: node)
      else
        item.allowed?(:edit, user, site: site, node: node)
      end
    end
  end
end
