require 'spec_helper'

describe "kana/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:part1) { create :accessibility_tool, cur_site: site }
  let!(:part2) { create :accessibility_tool_compat1, cur_site: site }
  let!(:layout) { create_cms_layout part1, part2 }
  let!(:item) do
    page_html = <<~HTML
      <div id="content">
        hello
      </div>
    HTML
    create :article_page, cur_site: site, layout: layout, html: page_html
  end
  let!(:theme_white) do
    create(
      :cms_theme_template, :cms_theme_template_white, cur_site: site, order: 0, state: "public", default_theme: "enabled"
    )
  end
  let!(:theme_blue) do
    create(
      :cms_theme_template, :cms_theme_template_blue, cur_site: site, order: 10, state: "public", default_theme: "disabled"
    )
  end
  let!(:theme_black) do
    create(
      :cms_theme_template, :cms_theme_template_black, cur_site: site, order: 20, state: "public", default_theme: "disabled",
    )
  end

  it do
    ::FileUtils.rm_f item.path

    visit item.full_url
    wait_for_all_themes_ready
    expect(page).to have_css(".accessibility__tool-wrap", count: 2)
    expect(page).to have_css("body[data-ss-theme='#{theme_white.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_css(".#{theme_white.class_name}.active")
      expect(page).to have_no_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_css(".#{theme_white.class_name}.active")
      expect(page).to have_no_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end

    within all(".accessibility__tool-wrap")[0] do
      click_on theme_blue.name
    end

    expect(page).to have_css("body[data-ss-theme='#{theme_blue.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end

    # reload したり別ページに遷移した場合、セッションから選択が復元されるはず
    visit item.full_url
    wait_for_all_themes_ready
    expect(page).to have_css(".accessibility__tool-wrap", count: 2)
    expect(page).to have_css("body[data-ss-theme='#{theme_blue.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".#{theme_white.class_name}", text: theme_white.name)
      expect(page).to have_css(".#{theme_blue.class_name}", text: theme_blue.name)
      expect(page).to have_css(".#{theme_black.class_name}", text: theme_black.name)

      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_css(".#{theme_blue.class_name}.active")
      expect(page).to have_no_css(".#{theme_black.class_name}.active")
    end

    within all(".accessibility__tool-wrap")[1] do
      click_on theme_black.name
    end

    expect(page).to have_css("body[data-ss-theme='#{theme_black.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_no_css(".#{theme_blue.class_name}.active")
      expect(page).to have_css(".#{theme_black.class_name}.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_no_css(".#{theme_white.class_name}.active")
      expect(page).to have_no_css(".#{theme_blue.class_name}.active")
      expect(page).to have_css(".#{theme_black.class_name}.active")
    end
  end
end
