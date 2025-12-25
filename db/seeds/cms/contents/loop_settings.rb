puts "# loop settings"

def save_loop_setting(data)
  puts data[:name]
  cond = { site_id: @site._id, name: data[:name] }
  item = Cms::LoopSetting.find_or_initialize_by(cond)
  item.attributes = data
  item.save

  item
end

# ============================================
# SHIRASAGI形式のループHTML設定
# ============================================

# 基本的な記事リスト（日付、タイトル、リンク）
save_loop_setting(
  name: "記事/基本記事リスト（SHIRASAGI形式）",
  description: "日付、タイトル、リンクを含む基本的な記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 10,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
      </header>
    </article>
  HTML
)

# サマリー付き記事リスト
save_loop_setting(
  name: "記事/サマリー付き記事リスト（SHIRASAGI形式）",
  description: "記事のサマリー（要約）を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 20,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
      </header>
      #{if summary}
      <div class="summary">#{summary}</div>
      #{end}
    </article>
  HTML
)

# カテゴリー付き記事リスト
save_loop_setting(
  name: "記事/カテゴリー付き記事リスト（SHIRASAGI形式）",
  description: "カテゴリー情報を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 30,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
        #{if categories}
        <div class="categories">#{categories}</div>
        #{end}
      </header>
    </article>
  HTML
)

# 画像付き記事リスト
save_loop_setting(
  name: "記事/画像付き記事リスト（SHIRASAGI形式）",
  description: "サムネイル画像を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 40,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <div class="article-content">
        #{if thumb.src}
        <div class="thumb">
          <img src="#{thumb.src}" alt="#{name}">
        </div>
        #{elsif img.src}
        <div class="thumb">
          <img src="#{img.src}" alt="#{name}">
        </div>
        #{end}
        <div class="text">
          <header>
            <time datetime="#{date}">#{date.long}</time>
            <h2><a href="#{url}">#{index_name}</a></h2>
          </header>
          #{if summary}
          <div class="summary">#{summary}</div>
          #{end}
        </div>
      </div>
    </article>
  HTML
)

# イベント日付付き記事リスト
save_loop_setting(
  name: "イベント/イベント日付付き記事リスト（SHIRASAGI形式）",
  description: "イベントの開催日時情報を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 50,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
        #{if event_dates}
        <div class="event-dates">#{event_dates.long}</div>
        #{end}
        #{if event_deadline}
        <div class="event-deadline">
          締切: <time datetime="#{event_deadline}">#{event_deadline.long}</time>
        </div>
        #{end}
      </header>
      #{if summary}
      <div class="summary">#{summary}</div>
      #{end}
    </article>
  HTML
)

# タグ付き記事リスト
save_loop_setting(
  name: "記事/タグ付き記事リスト（SHIRASAGI形式）",
  description: "タグ情報を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 60,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
        #{if tags}
        <div class="tags">#{tags}</div>
        #{end}
      </header>
      #{if summary}
      <div class="summary">#{summary}</div>
      #{end}
    </article>
  HTML
)

# シンプルなリスト（タイトルとリンクのみ）
save_loop_setting(
  name: "リスト/シンプルリスト（SHIRASAGI形式）",
  description: "タイトルとリンクのみのシンプルなリストテンプレート（SHIRASAGI形式）。外側の <ul> は upper_html/lower_html 側で設定してください（または Liquid 版のテンプレートをご利用ください）。",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 70,
  html: <<~'HTML'
    <li class="item-#{class} #{new} #{current}">
      <a href="#{url}">#{index_name}</a>
    </li>
  HTML
)

# テーブル形式のリスト
save_loop_setting(
  name: "リスト/テーブル形式リスト（SHIRASAGI形式）",
  description: "テーブル形式で表示する記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 90,
  html: <<~'HTML'
    <tr class="item-#{class} #{new} #{current}">
      <td class="date">
        <time datetime="#{date}">#{date.short}</time>
      </td>
      <td class="title">
        <a href="#{url}">#{index_name}</a>
      </td>
      <td class="categories">
        #{if categories}
          #{categories}
        #{else}
          -
        #{end}
      </td>
    </tr>
  HTML
)

# ノードリスト用テンプレート
save_loop_setting(
  name: "ノード/ノードリスト（SHIRASAGI形式）",
  description: "ノード（フォルダー）一覧を表示するテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 100,
  html: <<~'HTML'
    <article class="item-#{class} #{current}">
      <header>
        <h2><a href="#{url}">#{name}</a></h2>
      </header>
    </article>
  HTML
)

# 詳細情報付き記事リスト
save_loop_setting(
  name: "記事/詳細情報付き記事リスト（SHIRASAGI形式）",
  description: "グループ、更新日時などの詳細情報を含む記事リストテンプレート（SHIRASAGI形式）",
  html_format: "shirasagi",
  state: "public",
  loop_html_setting_type: "template",
  order: 110,
  html: <<~'HTML'
    <article class="item-#{class} #{new} #{current}">
      <header>
        <time datetime="#{date}">#{date.long}</time>
        <h2><a href="#{url}">#{index_name}</a></h2>
        #{if groups}
        <div class="groups">
          所属: #{groups}
        </div>
        #{end}
        #{if updated}
        <div class="updated">
          更新日時: <time datetime="#{updated}">#{updated.long}</time>
        </div>
        #{end}
      </header>
      #{if summary}
      <div class="summary">#{summary}</div>
      #{end}
    </article>
  HTML
)

# ============================================
# Liquid形式のループHTML設定
# ============================================

# 基本的な記事リスト（日付、タイトル、リンク）
save_loop_setting(
  name: "記事/基本記事リスト",
  description: "日付、タイトル、リンクを含む基本的な記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 10,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
      </header>
    </article>
    {% endfor %}
  HTML
)

# サマリー付き記事リスト
save_loop_setting(
  name: "記事/サマリー付き記事リスト",
  description: "記事のサマリー（要約）を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 20,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
      </header>
      {% if page.summary %}
      <div class="summary">{{ page.summary }}</div>
      {% endif %}
    </article>
    {% endfor %}
  HTML
)

# カテゴリー付き記事リスト
save_loop_setting(
  name: "記事/カテゴリー付き記事リスト",
  description: "カテゴリー情報を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 30,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
        {% if page.categories.size > 0 %}
        <div class="categories">
          {% for category in page.categories %}
          <span class="category {{ category.filename | replace: '/', '-' }}">
            <a href="{{ category.url }}">{{ category.name }}</a>
          </span>
          {% endfor %}
        </div>
        {% endif %}
      </header>
    </article>
    {% endfor %}
  HTML
)

# 画像付き記事リスト
save_loop_setting(
  name: "記事/画像付き記事リスト",
  description: "サムネイル画像を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 40,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <div class="article-content">
        {% assign thumb_src = page.thumb.url %}
        {% assign img_src = page.html | ss_img_src | expand_path: page.parent.url %}
        {% if thumb_src %}
        <div class="thumb">
          <img src="{{ thumb_src }}" alt="{{ page.name }}">
        </div>
        {% elsif img_src %}
        <div class="thumb">
          <img src="{{ img_src }}" alt="{{ page.name }}">
        </div>
        {% endif %}
        <div class="text">
          <header>
            <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
            <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
          </header>
          {% if page.summary %}
          <div class="summary">{{ page.summary }}</div>
          {% endif %}
        </div>
      </div>
    </article>
    {% endfor %}
  HTML
)

# イベント日付付き記事リスト
save_loop_setting(
  name: "イベント/イベント日付付き記事リスト",
  description: "イベントの開催日時情報を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 50,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
        {% if page.event_dates.size > 0 %}
        <div class="event-dates">
          {% for event_date_range in page.event_dates %}
            {% if event_date_range.size == 1 %}
            <time datetime="{{ event_date_range.first }}">{{ event_date_range.first | ss_date }}</time>
            {% else %}
            <time datetime="{{ event_date_range.first }}">{{ event_date_range.first | ss_date }}</time>〜
            <time datetime="{{ event_date_range.last }}">{{ event_date_range.last | ss_date }}</time>
            {% endif %}
          {% endfor %}
        </div>
        {% endif %}
        {% if page.event_deadline %}
        <div class="event-deadline">
          締切: <time datetime="{{ page.event_deadline }}">{{ page.event_deadline | ss_date }}</time>
        </div>
        {% endif %}
      </header>
      {% if page.summary %}
      <div class="summary">{{ page.summary }}</div>
      {% endif %}
    </article>
    {% endfor %}
  HTML
)

# タグ付き記事リスト
save_loop_setting(
  name: "記事/タグ付き記事リスト",
  description: "タグ情報を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 60,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
        {% if page.tags.size > 0 %}
        <div class="tags">
          {{ page.tags | join: " " }}
        </div>
        {% endif %}
      </header>
      {% if page.summary %}
      <div class="summary">{{ page.summary }}</div>
      {% endif %}
    </article>
    {% endfor %}
  HTML
)

# シンプルなリスト（タイトルとリンクのみ）
save_loop_setting(
  name: "リスト/シンプルリスト",
  description: "タイトルとリンクのみのシンプルなリストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 70,
  html: <<~HTML
    <ul>
    {% for page in pages %}
    <li class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a>
    </li>
    {% endfor %}
    </ul>
  HTML
)

# テーブル形式のリスト
save_loop_setting(
  name: "リスト/テーブル形式リスト",
  description: "テーブル形式で表示する記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 90,
  html: <<~HTML
    <table class="list-table">
      <thead>
        <tr>
          <th>日付</th>
          <th>タイトル</th>
          <th>カテゴリー</th>
        </tr>
      </thead>
      <tbody>
      {% for page in pages %}
      <tr class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
        <td class="date">
          <time datetime="{{ page.date }}">{{ page.date | ss_date: "short" }}</time>
        </td>
        <td class="title">
          <a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a>
        </td>
        <td class="categories">
          {% if page.categories.size > 0 %}
            {{ page.categories | map: "name" | join: ", " }}
          {% else %}
            -
          {% endif %}
        </td>
      </tr>
      {% endfor %}
      </tbody>
    </table>
  HTML
)

# ノードリスト用テンプレート
save_loop_setting(
  name: "ノード/ノードリスト",
  description: "ノード（フォルダー）一覧を表示するテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 100,
  html: <<~HTML
    {% for node in nodes %}
    <article class="item-{{ node.css_class }} {% if node.current? %}current{% endif %}">
      <header>
        <h2><a href="{{ node.url }}">{{ node.name }}</a></h2>
      </header>
    </article>
    {% endfor %}
  HTML
)

# 詳細情報付き記事リスト
save_loop_setting(
  name: "記事/詳細情報付き記事リスト",
  description: "グループ、更新日時などの詳細情報を含む記事リストテンプレート",
  html_format: "liquid",
  state: "public",
  loop_html_setting_type: "template",
  order: 110,
  html: <<~HTML
    {% for page in pages %}
    <article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">
      <header>
        <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>
        <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>
        {% if page.groups.size > 0 %}
        <div class="groups">
          所属: {{ page.groups | map: "last_name" | join: ", " }}
        </div>
        {% endif %}
        {% if page.updated %}
        <div class="updated">
          更新日時: <time datetime="{{ page.updated }}">{{ page.updated | ss_time }}</time>
        </div>
        {% endif %}
      </header>
      {% if page.summary %}
      <div class="summary">{{ page.summary }}</div>
      {% endif %}
    </article>
    {% endfor %}
  HTML
)

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
  name: "スニペット/フィルター/ファイルサイズ（人間可読形式）",
  loop_html_setting_type: "snippet",
  description: "ファイルサイズを人が視認しやすい形式で表示",
  html_format: "liquid",
  state: "public",
  order: 310,
  html: "{{ page.file.size | human_size }}"
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
