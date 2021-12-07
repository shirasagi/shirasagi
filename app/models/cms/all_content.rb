class Cms::AllContent
  include ActiveModel::Model

  # check reverse mapping in `app/jobs/cms/all_contents_import_job.rb`
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
    %w(size),
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

  class << self
    def enum_csv(site)
      new(site: site).enum_csv
    end

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def header
      FIELDS_DEF.map { |e| I18n.t("all_content.#{e[0]}") }
    end

    def valid_header?(path)
      path = path.path if path.respond_to?(:path)

      match_count = 0
      SS::Csv.foreach_row(path, headers: true) do |row|
        FIELDS_DEF.each do |e|
          if row.key?(I18n.t("all_content.#{e[0]}"))
            match_count += 1
          end
        end
        break
      end

      # if 80% of headers are matched, we considered it is valid
      match_count >= FIELDS_DEF.length * 0.8
    rescue
      false
    end
  end

  class Collection
    def self.wrap(array)
      if array.length <= 100
        ArrayCollection.new(array)
      else
        HashCollection.new(array)
      end
    end
  end

  class ArrayCollection
    def initialize(array)
      @array = array
    end

    def find(id)
      @array.find { |item| item.id == id }
    end

    def select(ids)
      @array.select { |item| ids.include?(item.id) }
    end
  end

  class HashCollection
    def initialize(array)
      @hash = array.index_by { |item| item.id }
    end

    def find(id)
      @hash[id]
    end

    def select(ids)
      ids.map { |id| @hash[id] }.compact
    end
  end

  attr_accessor :site

  def enum_csv
    Enumerator.new do |y|
      y << self.class.encode_sjis(self.class.header.to_csv)
      each_content do |content|
        content.site = site
        content.cur_site = site if content.respond_to?(:cur_site)
        y << self.class.encode_sjis(row(content).to_csv)
      end
    end
  end

  private

  def each_content(&block)
    page_criteria = Cms::Page.site(site).all
    all_page_ids = page_criteria.pluck(:id)
    all_page_ids.each_slice(20) do |page_ids|
      page_criteria.in(id: page_ids).to_a.each(&block)
    end

    node_criteria = Cms::Node.site(site).all
    all_node_ids = node_criteria.pluck(:id)
    all_node_ids.each_slice(20) do |node_ids|
      node_criteria.in(id: node_ids).to_a.each(&block)
    end
  end

  def row(content)
    FIELDS_DEF.map do |e|
      begin
        if e.length <= 1
          val = content.try(e[0])
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

  def to_page_id(key, content)
    return nil if !content.is_a?(Cms::Model::Page)
    content.id
  end

  def to_node_id(key, content)
    return nil if !content.is_a?(Cms::Model::Node)
    content.id
  end

  def all_layouts
    @all_layouts ||= begin
      all_layout_ids = Cms::Page.site(site).pluck(:layout_id)
      all_layout_ids += Cms::Node.site(site).pluck(:layout_id)
      all_layout_ids.uniq!
      all_layout_ids.compact!

      items = Cms::Layout.site(site).in(id: all_layout_ids).only(:filename).to_a
      Collection.wrap(items)
    end
  end

  def to_layout(key, content)
    return nil if content.layout_id.blank?

    layout = all_layouts.find(content.layout_id)
    return nil if layout.blank?

    layout.filename
  end

  def all_loop_settings
    @all_loop_settings ||= begin
      all_all_loop_setting_ids = Cms::Page.site(site).pluck(:loop_setting_id)
      all_all_loop_setting_ids += Cms::Node.site(site).pluck(:loop_setting_id)
      all_all_loop_setting_ids.uniq!
      all_all_loop_setting_ids.compact!

      items = Cms::LoopSetting.site(site).in(id: all_all_loop_setting_ids).only(:name).to_a
      Collection.wrap(items)
    end
  end

  def to_loop_setting(key, content)
    return nil if !content.respond_to?(:loop_setting_id)
    return I18n.t("cms.input_directly") if content.loop_setting_id.blank?

    loop_setting = all_loop_settings.find(content.loop_setting_id)
    return I18n.t("cms.input_directly") if loop_setting.blank?

    loop_setting.name
  end

  def to_url(key, content)
    content.full_url
  end

  def all_categories
    @all_categories ||= begin
      all_category_ids = Cms::Page.site(site).pluck(:category_ids)
      all_category_ids += Cms::Node.site(site).pluck(:category_ids)
      all_category_ids.flatten!
      all_category_ids.uniq!
      all_category_ids.compact!

      items = Cms::Node.site(site).in(id: all_category_ids).only(:name, :filename).to_a
      Collection.wrap(items)
    end
  end

  def to_categories(key, content)
    return nil if !content.respond_to?(:category_ids)
    return nil if content.category_ids.blank?

    categories = all_categories.select(content.category_ids)
    categories.map { |category| "#{category.filename}(#{category.name})" }.join("\n")
  end

  def all_files
    @all_files ||= begin
      all_file_ids = Cms::Page.site(site).pluck(:file_ids)
      all_file_ids += Cms::Node.site(site).pluck(:file_ids)
      all_file_ids.flatten!
      all_file_ids.uniq!
      all_file_ids.compact!

      items = SS::File.all.unscoped.in(id: all_file_ids).only(:name, :filename, :size).to_a
      Collection.wrap(items)
    end
  end

  def to_files(key, content)
    return nil if !content.respond_to?(:file_ids)
    return nil if content.file_ids.blank?

    files = all_files.select(content.file_ids)
    files.map(&:name).join("\n")
  end

  def to_file_urls(key, content)
    return nil if !content.respond_to?(:file_ids)
    return nil if content.file_ids.blank?

    files = all_files.select(content.file_ids)
    files.map(&:url).join("\n")
  end

  def to_map_points(key, content)
    content.map_points.map { |point| point[:loc].join(",") }.join("\n")
  end

  def all_groups
    @all_groups ||= begin
      all_group_ids = Cms::Page.site(site).pluck(:group_ids)
      all_group_ids += Cms::Node.site(site).pluck(:group_ids)
      all_group_ids.flatten!
      all_group_ids.uniq!
      all_group_ids.compact!

      items = Cms::Group.site(site).in(id: all_group_ids).only(:name).to_a
      Collection.wrap(items)
    end
  end

  def to_group_names(key, content)
    return nil if !content.respond_to?(:group_ids)
    return nil if content.group_ids.blank?

    groups = all_groups.select(content.group_ids)
    groups.map(&:name).join(",")
  end

  def to_label(key, content)
    content.label(key)
  end

  def to_file_size(key, content)
    size = 0

    content.path.tap do |path|
      if File.exist?(path)
        size += File.stat(path).size
      end
    end

    if content.respond_to?(:file_ids) && content.file_ids.present?
      files = all_files.select(content.file_ids)
      files.each do |file|
        size += file.size
      end
    end

    size
  end
end
