module Cms::NodeImportBase
  extend ActiveSupport::Concern
  include Cms::CsvImportBase

  included do
    cattr_accessor :model, instance_accessor: false
    self.model = Cms::Node
    attr_reader :site, :node, :user
  end

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]
    @keep_timestamp = opts[:keep_timestamp]
    basename = ::File.basename(file.name)
    put_log("import start #{basename}")
    Rails.logger.tagged(basename) do
      import_csv(file)
    end
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      puts message
    end
    Rails.logger.info(message)
  end

  def import_csv(file)
    self.class.each_csv(file) do |row, i|
      i += 1
      Rails.logger.tagged("#{i + 1}行目") do
        item = update_record(row)
        put_log("update #{i + 1}: #{item.name}") if item.present?
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_record(row)
    item = find_or_initialize_node(row)

    item.name = row['タイトル'] if item.respond_to?(:name)
    item.index_name = row['一覧用タイトル'] if item.respond_to?(:index_name)
    item.order = row['並び順'] if item.respond_to?(:order)

    update_layout(row, item)
    update_page_layout(row, item)

    item.shortcut = row['ショートカット'] if item.respond_to?(:shortcut)
    item.view_route = row['既定のモジュール'] if item.respond_to?(:view_route)
    item.keywords = row['キーワード'].split(',').map(&:strip) if row['キーワード'] && item.respond_to?(:keywords)
    item.description = row['概要'] if item.respond_to?(:description)
    item.summary_html = row['サマリー'] if item.respond_to?(:summary_html)
    item.conditions = row['検索条件(URL)'] if item.respond_to?(:conditions)
    item.sort = row['リスト並び順'] if item.respond_to?(:sort)
    item.limit = row['表示件数'] if item.respond_to?(:limit)
    item.new_days = row['NEWマーク期間'] if item.respond_to?(:new_days)
    item.loop_format = row['ループHTML形式'] if item.respond_to?(:loop_format)
    item.upper_html = row['上部HTML'] if item.respond_to?(:upper_html)
    item.loop_html = row['ループHTML(SHIRASAGI形式)'] if item.respond_to?(:loop_html)
    item.lower_html = row['下部HTML'] if item.respond_to?(:lower_html)
    item.loop_liquid = row['ループHTML(Liquid形式)'] if item.respond_to?(:loop_liquid)
    item.no_items_display_state = row['ページ未検出時表示'] if item.respond_to?(:no_items_display_state)
    item.substitute_html = row['代替HTML'] if item.respond_to?(:substitute_html)
    item.category_ids = row['カテゴリー設定'].split(',').map(&:strip) if row['カテゴリー設定'] && item.respond_to?(:category_ids)
    item.released_type = row['公開日時種別'] if item.respond_to?(:released_type)
    item.released = row['公開日時'] if item.respond_to?(:released)
    item.state = row['ステータス'] if item.respond_to?(:state)

    update_groups(row, item)

    item.save!

    item
  end

  def find_or_initialize_node(row)
    # "ファイル名" in csv that means basename
    # so actually field filename is "parent node's filename / basename"
    #
    # if node not given from job; it's root import
    # this case  field filename is "basename"
    basename = row['ファイル名']
    return nil if basename.blank?

    if @node
      filename = ::File.join(@node.filename, basename)
    else
      filename = basename
    end

    object = Cms::Node.site(@site).where(filename: filename).first
    if object.nil?

      # constantize by becomes_with_route
      route = row['フォルダー属性']
      object = Cms::Node::Base.new(route: route)
      object = object.becomes_with_route(route)

      # stop saving node when unknown route given
      if object.class == Cms::Node::Base
        raise "unknown route given (#{route})"
      end
    end

    object.cur_site = @site
    object.cur_node = @node if @node
    object.filename = filename
    object
  end

  def update_layout(row, item)
    return if row['レイアウト'].blank?

    layout_filename_match = row['レイアウト'].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    item.layout = layout
  end

  def update_page_layout(row, item)
    return if row['ページレイアウト'].blank?

    layout_filename_match = row['ページレイアウト'].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    item.layout = layout
  end

  def update_groups(row, item)
    return if row['管理グループ'].blank?

    @group_name_group_map ||= Cms::Group.all.site(@site).to_a.index_by(&:name)

    names = row['管理グループ'].split("\n").map(&:strip)
    groups = names.filter_map { |name| @group_name_group_map[name] }
    item.group_ids = groups.map(&:id)
  end
end
