puts "# loop settings"

def save_loop_setting(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Cms::LoopSetting.find_or_initialize_by(cond)
  item.attributes = data.slice(*item.fields.keys.map(&:to_sym))
  item.save

  item
end

# ============================================
# スニペット用データ（短いコード片）
# ============================================

# ページ変数 - 基本情報
save_loop_setting(
  name: "スニペット/ページ/ページ名",
  description: "ページ名を表示",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "snippet",
  order: 200,
  html: "{{ page.name }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページ一覧名",
  loop_html_setting_type: "snippet",
  description: "ページの一覧名を表示（index_nameがない場合はname）",
  html_format: "liquid",
  state: "public",
  order: 201,
  html: "{{ page.index_name | default: page.name }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページURL",
  loop_html_setting_type: "snippet",
  description: "ページのURLを表示",
  html_format: "liquid",
  state: "public",
  order: 202,
  html: "{{ page.url }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページフルURL",
  loop_html_setting_type: "snippet",
  description: "ページのフルURLを表示",
  html_format: "liquid",
  state: "public",
  order: 203,
  html: "{{ page.full_url }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページID",
  loop_html_setting_type: "snippet",
  description: "ページのIDを表示",
  html_format: "liquid",
  state: "public",
  order: 204,
  html: "{{ page.id }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページサマリー",
  loop_html_setting_type: "snippet",
  description: "ページのサマリーを表示",
  html_format: "liquid",
  state: "public",
  order: 205,
  html: "{{ page.summary }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページ概要",
  loop_html_setting_type: "snippet",
  description: "ページの概要を表示",
  html_format: "liquid",
  state: "public",
  order: 206,
  html: "{{ page.description }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページHTML",
  loop_html_setting_type: "snippet",
  description: "ページのHTMLを表示",
  html_format: "liquid",
  state: "public",
  order: 207,
  html: "{{ page.html }}"
)

# ページ変数 - 日付・時刻
save_loop_setting(
  name: "スニペット/ページ/ページ日時",
  loop_html_setting_type: "snippet",
  description: "ページの日時を表示（デフォルトフォーマット）",
  html_format: "liquid",
  state: "public",
  order: 210,
  html: "{{ page.date | ss_date }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページ日時（長い形式）",
  loop_html_setting_type: "snippet",
  description: "ページの日時を表示（長い形式：2024年1月1日）",
  html_format: "liquid",
  state: "public",
  order: 211,
  html: "{{ page.date | ss_date: \"long\" }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページ日時（ISO形式）",
  loop_html_setting_type: "snippet",
  description: "ページの日時を表示（ISO形式：2024-01-01）",
  html_format: "liquid",
  state: "public",
  order: 212,
  html: "{{ page.date | ss_date: \"iso\" }}"
)

save_loop_setting(
  name: "スニペット/ページ/ページ日時（短い形式）",
  loop_html_setting_type: "snippet",
  description: "ページの日時を表示（短い形式：1/1）",
  html_format: "liquid",
  state: "public",
  order: 213,
  html: "{{ page.date | ss_date: \"short\" }}"
)

save_loop_setting(
  name: "スニペット/ページ/更新日時",
  loop_html_setting_type: "snippet",
  description: "ページの更新日時を表示",
  html_format: "liquid",
  state: "public",
  order: 214,
  html: "{{ page.updated | ss_time }}"
)

save_loop_setting(
  name: "スニペット/ページ/公開日時",
  loop_html_setting_type: "snippet",
  description: "ページの公開日時を表示",
  html_format: "liquid",
  state: "public",
  order: 215,
  html: "{{ page.released | ss_date }}"
)

save_loop_setting(
  name: "スニペット/ページ/作成日時",
  loop_html_setting_type: "snippet",
  description: "ページの作成日時を表示",
  html_format: "liquid",
  state: "public",
  order: 216,
  html: "{{ page.created | ss_date }}"
)

# ページ変数 - リンク
save_loop_setting(
  name: "スニペット/ページ/リンク（ページ名）",
  loop_html_setting_type: "snippet",
  description: "ページ名をリンクとして表示",
  html_format: "liquid",
  state: "public",
  order: 220,
  html: "<a href=\"{{ page.url }}\">{{ page.index_name | default: page.name }}</a>"
)

save_loop_setting(
  name: "スニペット/ページ/リンク（タイトル）",
  loop_html_setting_type: "snippet",
  description: "ページ名をh2タグでリンクとして表示",
  html_format: "liquid",
  state: "public",
  order: 221,
  html: "<h2><a href=\"{{ page.url }}\">{{ page.index_name | default: page.name }}</a></h2>"
)

# ページ変数 - CSSクラス・状態
save_loop_setting(
  name: "スニペット/ページ/CSSクラス",
  loop_html_setting_type: "snippet",
  description: "ページのCSSクラスを表示",
  html_format: "liquid",
  state: "public",
  order: 230,
  html: "{{ page.css_class }}"
)

save_loop_setting(
  name: "スニペット/ページ/新着判定",
  loop_html_setting_type: "snippet",
  description: "ページが新着の場合に表示",
  html_format: "liquid",
  state: "public",
  order: 231,
  html: "{% if page.new? %}new{% endif %}"
)

save_loop_setting(
  name: "スニペット/ページ/現在ページ判定",
  loop_html_setting_type: "snippet",
  description: "ページが現在のページの場合に表示",
  html_format: "liquid",
  state: "public",
  order: 232,
  html: "{% if page.current? %}current{% endif %}"
)

save_loop_setting(
  name: "スニペット/ページ/CSSクラス属性（新着・現在）",
  loop_html_setting_type: "snippet",
  description: "CSSクラス、新着、現在ページの判定を含むクラス属性",
  html_format: "liquid",
  state: "public",
  order: 233,
  html: "class=\"item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}\""
)

# ページ変数 - カテゴリー
save_loop_setting(
  name: "スニペット/ページ/カテゴリー名（連結）",
  loop_html_setting_type: "snippet",
  description: "カテゴリー名をカンマ区切りで表示",
  html_format: "liquid",
  state: "public",
  order: 240,
  html: "{{ page.categories | map: \"name\" | join: \", \" }}"
)

save_loop_setting(
  name: "スニペット/ページ/カテゴリーリンク",
  loop_html_setting_type: "snippet",
  description: "カテゴリーをリンクとして表示",
  html_format: "liquid",
  state: "public",
  order: 241,
  html: "{% for category in page.categories %}<a href=\"{{ category.url }}\">{{ category.name }}</a>{% endfor %}"
)

save_loop_setting(
  name: "スニペット/ページ/カテゴリー（spanタグ）",
  loop_html_setting_type: "snippet",
  description: "カテゴリーをspanタグで表示",
  html_format: "liquid",
  state: "public",
  order: 242,
  html: "{% for category in page.categories %}" \
        "<span class=\"category {{ category.filename | replace: '/', '-' }}\">" \
        "<a href=\"{{ category.url }}\">{{ category.name }}</a></span>{% endfor %}"
)

save_loop_setting(
  name: "スニペット/ページ/カテゴリーCSSクラス",
  loop_html_setting_type: "snippet",
  description: "カテゴリーのbasenameにitem-を付けてスペース区切りで表示",
  html_format: "liquid",
  state: "public",
  order: 243,
  html: "{{ page.categories | map: \"basename\" | ss_prepend: \"item-\" | join: \" \" }}"
)

# ページ変数 - タグ
save_loop_setting(
  name: "スニペット/ページ/タグ",
  loop_html_setting_type: "snippet",
  description: "ページのタグをスペース区切りで表示",
  html_format: "liquid",
  state: "public",
  order: 250,
  html: "{{ page.tags | join: \" \" }}"
)

# ページ変数 - グループ
save_loop_setting(
  name: "スニペット/ページ/管理グループ",
  loop_html_setting_type: "snippet",
  description: "ページの管理グループ名をカンマ区切りで表示",
  html_format: "liquid",
  state: "public",
  order: 260,
  html: "{{ page.groups | map: \"last_name\" | join: \", \" }}"
)

save_loop_setting(
  name: "スニペット/ページ/管理グループ（最初）",
  loop_html_setting_type: "snippet",
  description: "ページの最初の管理グループ名を表示",
  html_format: "liquid",
  state: "public",
  order: 261,
  html: "{{ page.groups[0].last_name }}"
)

# ページ変数 - 画像
save_loop_setting(
  name: "スニペット/ページ/サムネイル画像URL",
  loop_html_setting_type: "snippet",
  description: "ページのサムネイル画像URLを表示",
  html_format: "liquid",
  state: "public",
  order: 270,
  html: "{{ page.thumb.url }}"
)

save_loop_setting(
  name: "スニペット/ページ/画像src",
  loop_html_setting_type: "snippet",
  description: "ページHTMLから最初の画像のsrcを取得（デフォルト画像あり）",
  html_format: "liquid",
  state: "public",
  order: 271,
  html: "{% assign img_src = page.html | ss_img_src | expand_path: page.parent.url %}" \
        "{{ img_src | default: \"/assets/img/dummy.png\" }}"
)

save_loop_setting(
  name: "スニペット/ページ/サムネイルsrc",
  loop_html_setting_type: "snippet",
  description: "サムネイル画像URL（なければHTMLから画像、それもなければデフォルト画像）",
  html_format: "liquid",
  state: "public",
  order: 272,
  html: "{% assign thumb_src = page.thumb.url %}" \
        "{% assign img_src = page.html | ss_img_src | expand_path: page.parent.url %}" \
        "{{ thumb_src | default: img_src | default: \"/assets/img/dummy.png\" }}"
)

save_loop_setting(
  name: "スニペット/ページ/画像タグ（サムネイル）",
  loop_html_setting_type: "snippet",
  description: "サムネイル画像をimgタグで表示",
  html_format: "liquid",
  state: "public",
  order: 273,
  html: "<img src=\"{{ page.thumb.url }}\" alt=\"{{ page.name }}\">"
)

# ページ変数 - イベント
save_loop_setting(
  name: "スニペット/ページ/イベント開催日時",
  loop_html_setting_type: "snippet",
  description: "イベントの開催日時を表示",
  html_format: "liquid",
  state: "public",
  order: 280,
  html: "{% for event_date_range in page.event_dates %}" \
        "{% if event_date_range.size == 1 %}" \
        "<time datetime=\"{{ event_date_range.first }}\">" \
        "{{ event_date_range.first | ss_date }}</time>" \
        "{% else %}" \
        "<time datetime=\"{{ event_date_range.first }}\">" \
        "{{ event_date_range.first | ss_date }}</time>〜" \
        "<time datetime=\"{{ event_date_range.last }}\">" \
        "{{ event_date_range.last | ss_date }}</time>" \
        "{% endif %}{% endfor %}"
)

save_loop_setting(
  name: "スニペット/ページ/イベント申込締切",
  loop_html_setting_type: "snippet",
  description: "イベントの申込締切を表示",
  html_format: "liquid",
  state: "public",
  order: 281,
  html: "{{ page.event_deadline | ss_date }}"
)

save_loop_setting(
  name: "スニペット/ページ/イベントタイトル",
  loop_html_setting_type: "snippet",
  description: "イベントタイトルを表示",
  html_format: "liquid",
  state: "public",
  order: 282,
  html: "{{ page.event_name }}"
)

# ノード変数
save_loop_setting(
  name: "スニペット/ノード/ノード名",
  loop_html_setting_type: "snippet",
  description: "ノード名を表示",
  html_format: "liquid",
  state: "public",
  order: 290,
  html: "{{ node.name }}"
)

save_loop_setting(
  name: "スニペット/ノード/ノードURL",
  loop_html_setting_type: "snippet",
  description: "ノードのURLを表示",
  html_format: "liquid",
  state: "public",
  order: 291,
  html: "{{ node.url }}"
)

save_loop_setting(
  name: "スニペット/ノード/ノード内ページ数",
  loop_html_setting_type: "snippet",
  description: "ノード内のページ数を表示",
  html_format: "liquid",
  state: "public",
  order: 292,
  html: "{{ node.pages | size }}"
)

# フィルター - 日付・時刻
save_loop_setting(
  name: "スニペット/フィルター/日付（デフォルト形式）",
  loop_html_setting_type: "snippet",
  description: "日付をデフォルトフォーマットで表示（%Y/%1m/%1d）",
  html_format: "liquid",
  state: "public",
  order: 300,
  html: "{{ page.date | ss_date: \"default\" }}"
)

save_loop_setting(
  name: "スニペット/フィルター/日付（ISO形式）",
  loop_html_setting_type: "snippet",
  description: "日付をISO形式で表示（%Y-%m-%d）",
  html_format: "liquid",
  state: "public",
  order: 301,
  html: "{{ page.date | ss_date: \"iso\" }}"
)

save_loop_setting(
  name: "スニペット/フィルター/日付（長い形式）",
  loop_html_setting_type: "snippet",
  description: "日付を長い形式で表示（%Y年%1m月%1d日）",
  html_format: "liquid",
  state: "public",
  order: 302,
  html: "{{ page.date | ss_date: \"long\" }}"
)

save_loop_setting(
  name: "スニペット/フィルター/日付（短い形式）",
  loop_html_setting_type: "snippet",
  description: "日付を短い形式で表示（%1m/%1d）",
  html_format: "liquid",
  state: "public",
  order: 303,
  html: "{{ page.date | ss_date: \"short\" }}"
)

save_loop_setting(
  name: "スニペット/フィルター/日時（デフォルト形式）",
  loop_html_setting_type: "snippet",
  description: "日時をデフォルトフォーマットで表示（%Y/%1m/%1d %H:%M）",
  html_format: "liquid",
  state: "public",
  order: 304,
  html: "{{ page.date | ss_time: \"default\" }}"
)

save_loop_setting(
  name: "スニペット/フィルター/日時（長い形式）",
  loop_html_setting_type: "snippet",
  description: "日時を長い形式で表示（%Y年%1m月%1d日 %H時%M分）",
  html_format: "liquid",
  state: "public",
  order: 305,
  html: "{{ page.date | ss_time: \"long\" }}"
)

# フィルター - その他
save_loop_setting(
  name: "スニペット/定型フォーム/ファイルサイズ（人間可読形式）",
  loop_html_setting_type: "snippet",
  description: "定型フォームのファイル入力のサイズを人が視認しやすい形式で表示",
  html_format: "liquid",
  state: "public",
  order: 310,
  html: "{{ value.file.size | human_size }}"
)

save_loop_setting(
  name: "スニペット/フィルター/数値（3桁区切り）",
  loop_html_setting_type: "snippet",
  description: "数値を3桁区切り文字列に変換",
  html_format: "liquid",
  state: "public",
  order: 311,
  html: "{{ page.order | delimited }}"
)

save_loop_setting(
  name: "スニペット/フィルター/HTMLサニタイズ",
  loop_html_setting_type: "snippet",
  description: "HTMLとして不適切な文字を削除",
  html_format: "liquid",
  state: "public",
  order: 312,
  html: "{{ page.summary | sanitize }}"
)

# 定型フォーム - value変数
save_loop_setting(
  name: "スニペット/定型フォーム/定型フォームHTML",
  loop_html_setting_type: "snippet",
  description: "定型フォームの入力値をHTML化したもの（既定値）",
  html_format: "liquid",
  state: "public",
  order: 320,
  html: "{{ value.html }}"
)

save_loop_setting(
  name: "スニペット/定型フォーム/定型フォーム入力値",
  loop_html_setting_type: "snippet",
  description: "定型フォームの入力値（一行入力、複数行入力など）",
  html_format: "liquid",
  state: "public",
  order: 321,
  html: "{{ value.value }}"
)

save_loop_setting(
  name: "スニペット/定型フォーム/定型フォームブロック名",
  loop_html_setting_type: "snippet",
  description: "定型フォームのブロック名称",
  html_format: "liquid",
  state: "public",
  order: 322,
  html: "{{ value.name }}"
)

save_loop_setting(
  name: "スニペット/定型フォーム/定型フォーム日付",
  loop_html_setting_type: "snippet",
  description: "定型フォームの日付入力値を表示",
  html_format: "liquid",
  state: "public",
  order: 323,
  html: "{{ value.date | ss_date: \"long\" }}"
)

save_loop_setting(
  name: "スニペット/定型フォーム/リンク（定型フォーム）",
  loop_html_setting_type: "snippet",
  description: "定型フォームのURL入力値をリンクとして表示",
  html_format: "liquid",
  state: "public",
  order: 324,
  html: "<a href=\"{{ value.link_url }}\">{{ value.link_label | default: value.link_url }}</a>"
)

# 時間タグ
save_loop_setting(
  name: "スニペット/ページ/timeタグ（日付）",
  loop_html_setting_type: "snippet",
  description: "日付をtimeタグで表示",
  html_format: "liquid",
  state: "public",
  order: 330,
  html: "<time datetime=\"{{ page.date }}\">{{ page.date | ss_date: \"long\" }}</time>"
)

save_loop_setting(
  name: "スニペット/ページ/timeタグ（日時）",
  loop_html_setting_type: "snippet",
  description: "日時をtimeタグで表示",
  html_format: "liquid",
  state: "public",
  order: 331,
  html: "<time datetime=\"{{ page.updated }}\">{{ page.updated | ss_time }}</time>"
)

# ページ変数 - パス・階層
save_loop_setting(
  name: "スニペット/ページ/ベース名",
  loop_html_setting_type: "snippet",
  description: "ページのベース名（パス末尾）を表示",
  html_format: "liquid",
  state: "public",
  order: 340,
  html: "{{ page.basename }}"
)

save_loop_setting(
  name: "スニペット/ページ/ファイル名",
  loop_html_setting_type: "snippet",
  description: "ページのファイル名（パス）を表示",
  html_format: "liquid",
  state: "public",
  order: 341,
  html: "{{ page.filename }}"
)

save_loop_setting(
  name: "スニペット/ページ/階層の深さ",
  loop_html_setting_type: "snippet",
  description: "ページの階層の深さを表示",
  html_format: "liquid",
  state: "public",
  order: 342,
  html: "{{ page.depth }}"
)

save_loop_setting(
  name: "スニペット/ページ/並び順",
  loop_html_setting_type: "snippet",
  description: "ページの並び順の値を表示",
  html_format: "liquid",
  state: "public",
  order: 343,
  html: "{{ page.order }}"
)

# ページ変数 - 親ページ
save_loop_setting(
  name: "スニペット/ページ/親ページURL",
  loop_html_setting_type: "snippet",
  description: "親ページのURLを表示",
  html_format: "liquid",
  state: "public",
  order: 350,
  html: "{{ page.parent.url }}"
)

save_loop_setting(
  name: "スニペット/ページ/親ページ名",
  loop_html_setting_type: "snippet",
  description: "親ページの名称を表示",
  html_format: "liquid",
  state: "public",
  order: 351,
  html: "{{ page.parent.name }}"
)

# パーツ
save_loop_setting(
  name: "スニペット/パーツ/パーツHTML",
  loop_html_setting_type: "snippet",
  description: "キーで指定したパーツのHTMLを表示（キー名は適宜変更）",
  html_format: "liquid",
  state: "public",
  order: 360,
  html: "{{ parts[\"key_name\"].html }}"
)

# コレクションフィルター
save_loop_setting(
  name: "スニペット/フィルター/フォルダ内ページ一覧",
  loop_html_setting_type: "snippet",
  description: "ノード配下のページ一覧を取得（第2引数は取得件数）",
  html_format: "liquid",
  state: "public",
  order: 370,
  html: "{% assign list = node | public_list: 10 %}"
)

save_loop_setting(
  name: "スニペット/フィルター/フォーム値で絞り込み",
  loop_html_setting_type: "snippet",
  description: "定型フォームのカラム値でページ一覧を絞り込み（key.valueで指定）",
  html_format: "liquid",
  state: "public",
  order: 371,
  html: "{% assign list = pages | filter_by_column_value: \"key.value\" %}"
)

save_loop_setting(
  name: "スニペット/フィルター/フォーム値でソート",
  loop_html_setting_type: "snippet",
  description: "定型フォームのカラム値でページ一覧を並び替え（昇順）",
  html_format: "liquid",
  state: "public",
  order: 372,
  html: "{% assign list = pages | sort_by_column_value: \"key\" %}"
)

save_loop_setting(
  name: "スニペット/フィルター/同名ページ取得",
  loop_html_setting_type: "snippet",
  description: "タイトルが一致する別ノードのページ一覧を取得",
  html_format: "liquid",
  state: "public",
  order: 373,
  html: "{% assign list = page | same_name_pages %}"
)

# イベントフィルター
save_loop_setting(
  name: "スニペット/フィルター/有効な繰り返しイベント抽出",
  loop_html_setting_type: "snippet",
  description: "繰り返しイベントから現在有効なもののみを抽出",
  html_format: "liquid",
  state: "public",
  order: 380,
  html: "{% assign recurrences = page.event_recurrences | event_active_recurrences %}"
)

save_loop_setting(
  name: "スニペット/フィルター/繰り返しイベント要約",
  loop_html_setting_type: "snippet",
  description: "繰り返しイベントを簡潔な文字列に要約",
  html_format: "liquid",
  state: "public",
  order: 381,
  html: "{{ page.event_recurrences | event_recurrence_summary }}"
)
