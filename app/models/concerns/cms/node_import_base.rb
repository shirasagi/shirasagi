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
    class_name = row['フォルダー属性'].split('/').map(&:camelize).join('::Node::')
    klass = class_name.constantize
    node = klass.find_or_initialize_by(basename: row['ファイル名'], site: @site, user: @user)
    
    node.route = row['フォルダー属性'] if node.respond_to?(:route)
    node.name = row['タイトル'] if node.respond_to?(:name)
    node.index_name = row['一覧用タイトル'] if node.respond_to?(:index_name)
  
    if row['レイアウト'].present?
      layout_filename_match = row['レイアウト'].match(/\(([^)]+)\)/)
      layout_filename = layout_filename_match[1] if layout_filename_match
      node.layout = Cms::Layout.find_by(filename: layout_filename) if layout_filename
    end
  
    node.order = row['並び順'] if node.respond_to?(:order)
  
    if row['ページレイアウト'].present?
      layout_filename_match = row['ページレイアウト'].match(/\(([^)]+)\)/)
      layout_filename = layout_filename_match[1] if layout_filename_match
      node.page_layout = Cms::Layout.find_by(filename: layout_filename) if layout_filename
    end
  
    node.shortcut = row['ショートカット'] if node.respond_to?(:shortcut)
    node.view_route = row['既定のモジュール'] if node.respond_to?(:view_route)
    node.keywords = row['キーワード'].split(',').map(&:strip) if row['キーワード'] && node.respond_to?(:keywords)
    node.description = row['概要'] if node.respond_to?(:description)
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
    node.group_ids = row['管理グループ'].split(',').map(&:strip) if row['管理グループ'] && node.respond_to?(:group_ids)
    node.state = row['ステータス'] if node.respond_to?(:state)
    
    node.save!
  
    node
  end
  
  

end