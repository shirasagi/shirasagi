module Cms::FormHelper
  def ancestral_layouts(node, cur_layout = nil)
    node  = @cur_node if !node || node.new_record?
    items = []
    if node
      Cms::Layout.site(@cur_site).node(node).sort(name: 1).each do |item|
        items << ["#{node.name}/#{item.name}", item.id]
      end
      node.parents.sort(depth: -1).each do |parent|
        Cms::Layout.site(@cur_site).node(parent).sort(name: 1).each do |item|
          items << ["#{parent.name}/#{item.name}", item.id]
        end
      end
    end
    Cms::Layout.site(@cur_site).where(depth: 1).sort(name: 1).each do |item|
      items << [item.name, item.id]
    end
    if cur_layout
      unless items.find { |_name, id| id == cur_layout.id }
        items.prepend([cur_layout.name, cur_layout.id])
      end
    end
    items
  end

  def ancestral_body_layouts
    items = []
    Cms::BodyLayout.site(@cur_site).sort(name: 1).each do |item|
      items << [item.name, item.id] if item.parts.present?
    end
    items
  end

  def ancestral_loop_settings(format = nil)
    items = []
    if format == "liquid"
      settings = Cms::LoopSetting.site(@cur_site).liquid
    else
      settings = Cms::LoopSetting.site(@cur_site).shirasagi
    end
    settings.each do |item|
      # loop_html_setting_type == "template"のデータのみを返す
      next unless item.loop_html_setting_type_template?
      items << [item.name, item.id, item.description]
    end
    items
  end

  def ancestral_html_settings_liquid
    items = []
    settings = Cms::LoopSetting.site(@cur_site).liquid
    settings.each do |item|
      # loop_html_setting_type == "snippet"のデータのみを返す
      next unless item.loop_html_setting_type_snippet?
      attrs = { "data-snippet" => item.html.to_s }
      attrs["data-description"] = item.description if item.description.present?
      # enum化により、名前をそのまま使用（プレフィックス削除不要）
      items << [item.name, item.id, attrs]
    end
    items
  end

  def ancestral_forms
    if @cur_node.nil?
      st_forms = Cms::Form.all
    else
      st_forms = @cur_node.st_forms rescue nil
      st_forms ||= Cms::Form.none
    end
    st_forms = st_forms.site(@cur_site)
    st_forms = st_forms.and_public
    st_forms = st_forms.allow(:read, @cur_user, site: @cur_site)
    st_forms.order_by(update: 1)
  end

  # 指定データ配列(snippet_option_list)を select用optgroup(option)構造へ変換
  #
  # items: [["スニペット/ページ/ページ名", id1, {data}], ["スニペット/ページ/ページID", id2, {data}], ["スニペット/タグ", id3, {data}]]
  # 戻り値: HTML Safe
  def options_with_optgroup_for_snippets(items, input_direct_label: nil)
    input_direct_label ||= t("cms.input_directly")
    groups = Hash.new { |h, k| h[k] = [] }
    nogroup = []
    items.each do |name, id, attrs|
      # enum化により、プレフィックス判定は不要（ancestral_html_settings_liquidで既にフィルタリング済み）
      if name.include?("/")
        group, leaf = name.split("/", 2)
        groups[group] << [leaf, id, attrs]
      else
        nogroup << [name, id, attrs]
      end
    end
    html = []
    # 直接入力optionはグループ外で必ず先頭
    html << tag.option(input_direct_label, value: "")
    # グループ外（ルート）option
    nogroup.each do |name, id, attrs|
      # data-snippetキーをsnippetキーに変換（Railsのtag.optionはdata-プレフィックスなしを期待）
      data_attrs = attrs.dup
      if data_attrs.key?("data-snippet")
        data_attrs["snippet"] = data_attrs.delete("data-snippet")
      end
      # data-descriptionキーをdescriptionキーに変換（Railsのtag.optionはdata-プレフィックスなしを期待）
      if data_attrs.key?("data-description")
        data_attrs["description"] = data_attrs.delete("data-description")
      end
      html << tag.option(name, value: id, data: data_attrs)
    end
    # グループoptgroup(全グループでclass: 'title')
    groups.keys.sort.each do |group|
      html << tag.optgroup(label: group, class: 'title') do
        groups[group].map do |leaf, id, attrs|
          # data-snippetキーをsnippetキーに変換（Railsのtag.optionはdata-プレフィックスなしを期待）
          data_attrs = attrs.dup
          if data_attrs.key?("data-snippet")
            data_attrs["snippet"] = data_attrs.delete("data-snippet")
          end
          # data-descriptionキーをdescriptionキーに変換（Railsのtag.optionはdata-プレフィックスなしを期待）
          if data_attrs.key?("data-description")
            data_attrs["description"] = data_attrs.delete("data-description")
          end
          tag.option(leaf, value: id, data: data_attrs)
        end.join.html_safe
      end
    end
    safe_join(html)
  end

  # 指定データ配列(loop_setting_option_list)を select用optgroup(option)構造へ変換
  #
  # items: [["test/test1", id1, description1], ["test/test2", id2, description2], ["root", id3, description3]]
  # または [["test/test1", id1], ["test/test2", id2], ["root", id3]] (後方互換性のため)
  # 戻り値: HTML Safe
  def options_with_optgroup_for_loop_settings(items, input_direct_label: nil)
    input_direct_label ||= t("cms.input_directly")
    groups = Hash.new { |h, k| h[k] = [] }
    nogroup = []
    items.each do |item|
      # 後方互換性のため、配列の長さで判定
      name = item[0]
      id = item[1]
      description = item.length >= 3 ? item[2] : nil

      if name.include?("/")
        group, leaf = name.split("/", 2)
        groups[group] << [leaf, id, description]
      else
        nogroup << [name, id, description]
      end
    end
    html = []
    # 直接入力optionはグループ外で必ず先頭
    html << tag.option(input_direct_label, value: "")
    # グループ外（ルート）option
    nogroup.each do |name, id, description|
      option_attrs = { value: id }
      option_attrs[:data] = { description: description } if description.present?
      html << tag.option(name, **option_attrs)
    end
    # グループoptgroup(全グループでclass: 'title')
    groups.keys.sort.each do |group|
      html << tag.optgroup(label: group, class: 'title') do
        groups[group].map do |leaf, id, description|
          option_attrs = { value: id }
          option_attrs[:data] = { description: description } if description.present?
          tag.option(leaf, **option_attrs)
        end.join.html_safe
      end
    end
    safe_join(html)
  end
end
