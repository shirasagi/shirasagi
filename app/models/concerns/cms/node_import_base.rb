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
    @task.log(message) if @task
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
    node = find_or_initialize_node(row)

    # TODO and Memo:
    # variable name of "node" is duplicated in this namespace
    # this is dangerous
    #
    # attr_reader's node... node of import from
    # node =... node of creating now

    node.name = row['タイトル'] if node.respond_to?(:name)
    node.index_name = row['一覧用タイトル'] if node.respond_to?(:index_name)
    node.order = row['並び順'] if node.respond_to?(:order)

    update_layout(row, node)
    update_page_layout(row, node)

    node.shortcut = row['ショートカット'] if node.respond_to?(:shortcut)
    node.view_route = row['既定のモジュール'] if node.respond_to?(:view_route)
    node.keywords = row['キーワード'].split(',').map(&:strip) if row['キーワード'] && node.respond_to?(:keywords)
    node.description = row['概要'] if node.respond_to?(:description)
    node.summary_html = row['サマリー'] if node.respond_to?(:summary_html)
    # node.summary = row['サマリー'] if node.respond_to?(:summary)
    node.conditions = row['検索条件(URL)'] if node.respond_to?(:conditions)
    node.sort = row['リスト並び順'] if node.respond_to?(:sort)
    node.limit = row['表示件数'] if node.respond_to?(:limit)
    node.new_days = row['NEWマーク期間'] if node.respond_to?(:new_days)
    node.loop_format = row['ループHTML形式'] if node.respond_to?(:loop_format)
    node.upper_html = row['上部HTML'] if node.respond_to?(:upper_html)
    node.loop_html = row['ループHTML(SHIRASAGI形式)'] if node.respond_to?(:loop_html)
    node.lower_html = row['下部HTML'] if node.respond_to?(:lower_html)
    node.loop_liquid = row['ループHTML(Liquid形式)'] if node.respond_to?(:loop_liquid)
    node.no_items_display_state = row['ページ未検出時表示'] if node.respond_to?(:no_items_display_state)
    node.substitute_html = row['代替HTML'] if node.respond_to?(:substitute_html)
    node.category_ids = row['カテゴリー設定'].split(',').map(&:strip) if row['カテゴリー設定'] && node.respond_to?(:category_ids)
    node.released_type = row['公開日時種別'] if node.respond_to?(:released_type)
    node.released = row['公開日時'] if node.respond_to?(:released)
    node.state = row['ステータス'] if node.respond_to?(:state)

    update_groups(row, node)

    node.save!

    node
  end

  def find_or_initialize_node(row)
    # TODO and Memo:
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

    # TODO and Memo:
    # uniq key is field filename and site_id; user_id is not uniq
    # Cms::Node.find return node instance that instance of correct class (it's use becomes_with_route internally)
    # try find node from conditions
    node = Cms::Node.site(@site).where(filename: filename).first
    if node.nil?

      # constantize by becomes_with_route
      route = row['フォルダー属性']
      node = Cms::Node::Base.new(route: route)
      node = node.becomes_with_route(route)

      # stop saving node when unknown route given
      if node.class == Cms::Node::Base
        raise "unknown route given (#{route})"
      end
    end

    # old codes:
    # node = klass.find_or_initialize_by(filename: filename, site_id: @site.id)
    #class_name = row['フォルダー属性'].split('/').map(&:camelize).join('::Node::')
    #klass = class_name.constantize

    node.cur_site = @site
    node.cur_node = @node if @node
    node.filename = filename
    node
  end

  def update_layout(row, node)
    return if row['レイアウト'].blank?

    # TODO and Memo:
    # layout is relation field
    # avoid exceptions of caused by find error
    #
    # set nil relation when layout not found
    # and continue saving node
    # these cases validate by "node.save"
    layout_filename_match = row['レイアウト'].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    node.layout = layout
  end

  def update_page_layout(row, node)
    return if row['ページレイアウト'].blank?

    # TODO and Memo:
    # page_layout is relation field
    # avoid exceptions of caused by find error
    #
    # set nil relation when page_layout not found
    # and continue saving node
    # these cases validate by "node.save"
    layout_filename_match = row['ページレイアウト'].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    node.layout = layout
  end

  def update_groups(row, node)
    return if row['管理グループ'].blank?

    # TODO and Memo:
    # group_ids is relation field
    # avoid exceptions of caused by find error
    #
    # set nil relation when groups not found
    # and continue saving node
    # these cases validate by "node.save"

    # find all groups belonging to the site, ref Cms::PageImportBase
    @group_name_group_map ||= Cms::Group.all.site(@site).to_a.index_by(&:name)

    names = row['管理グループ'].split("\n").map(&:strip)
    groups = names.filter_map { |name| @group_name_group_map[name] }
    node.group_ids = groups.map(&:id)
  end
end
