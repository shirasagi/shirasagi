require 'csv'

class Cms::NodeExporter
  # TODO and Memo:
  # should unify our naming conventions
  #
  # Cms::NodeExporter => Cms::Node::Exporter
  # or
  # Cms::Node::Importer => Cms::NodeImporter

  include ActiveModel::Model

  # TODO and Memo:
  # not used accessor of mode
  attr_accessor :mode, :site, :criteria

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      #adding header once
      csv_headers.each do |header|
        drawer.column drawer_columns["#{header}"] do
          drawer.head { header }
        end
      end
    end

    # TODO and Memo:
    # this enum block outputs attirbutes as simple_column (just outputs  string or integer
    # need to consider of relation fields and label fields
    #
    # please check the spec/models/cms/node/exporter/basic_spec.rb
    # expected outputs is described
    drawer.enum(criteria, options)
  end

  private

  # TODO and Memo:
  # writing localized string in logic code directly is not preferred
  # if possible, please put these keys and values in ja.yml
  # the same goes for Cms::Node::Importer's "row[key]"
  #
  # e.g.
  # I18n.t("cms.import_node.headers")
  # > [ key => value, key => value... ]
  def csv_headers
    ['ファイル名', 'フォルダー属性', 'タイトル', '一覧用タイトル', '並び順', 'レイアウト', 'ページレイアウト',
     'ショートカット', '既定のモジュール', 'キーワード', '概要', 'サマリー', '検索条件(URL)',
     'リスト並び順', '表示件数', 'NEWマーク期間', 'ループHTML形式', '上部HTML', 'ループHTML(SHIRASAGI形式)',
     '下部HTML', 'ループHTML(Liquid形式)', 'ページ未検出時表示', '代替HTML', 'カテゴリー設定',
     '公開日時種別', '公開日時', 'ステータス', '管理グループ']
  end

  def drawer_columns
    {
      'ファイル名' => :filename,
      'フォルダー属性' => :route,
      'タイトル' => :name,
      '一覧用タイトル' => :index_name,
      '並び順' => :order,
      'レイアウト' => :layout_filename,
      'ページレイアウト' => :page_layout_filename,
      'ショートカット' => :shortcut,
      '既定のモジュール' => :view_route,
      'キーワード' => :keywords,
      '概要' => :description,
      'サマリー' => :summary_html,
      '検索条件(URL)' => :conditions,
      'リスト並び順' => :sort,
      '表示件数' => :limit,
      'NEWマーク期間' => :new_days,
      'ループHTML形式' => :loop_format,
      '上部HTML' => :upper_html,
      'ループHTML(SHIRASAGI形式)' => :loop_html,
      '下部HTML' => :lower_html,
      'ループHTML(Liquid形式)' => :loop_liquid,
      'ページ未検出時表示' => :no_items_display_state,
      '代替HTML' => :substitute_html,
      'カテゴリー設定' => :category_ids,
      '公開日時種別' => :released_type,
      '公開日時' => :released,
      'ステータス' => :state,
      '管理グループ' => :group_ids
    }
  end
end
