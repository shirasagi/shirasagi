require 'spec_helper'

describe "kana/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:part1) { create :accessibility_tool, cur_site: site }
  let!(:part2) { create :accessibility_tool_compat, cur_site: site }
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
      :cms_theme_template, cur_site: site, name: "白", class_name: "white", order: 0, state: "public", default_theme: "enabled",
      high_contrast_mode: "disabled", font_color: nil, background_color: nil, css_path: nil
    )
  end
  let!(:theme_blue) do
    create(
      :cms_theme_template, cur_site: site, name: "青", class_name: "blue", order: 10, state: "public", default_theme: "disabled",
      high_contrast_mode: "enabled", font_color: "#fff", background_color: "#06c", css_path: nil
    )
  end
  let!(:theme_black) do
    create(
      :cms_theme_template, cur_site: site, name: "黒", class_name: "black", order: 20, state: "public", default_theme: "disabled",
      high_contrast_mode: "disabled", font_color: nil, background_color: nil, css_path: "/css/black.css"
    )
  end

  it do
    ::FileUtils.rm_f item.path

    visit item.full_url
    expect(page).to have_css(".accessibility__tool-wrap", count: 2)
    expect(page).to have_css("body[data-ss-theme='#{theme_white.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_css(".white.active")
      expect(page).to have_no_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_css(".white.active")
      expect(page).to have_no_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end

    within all(".accessibility__tool-wrap")[0] do
      click_on theme_blue.name
    end

    expect(page).to have_css("body[data-ss-theme='#{theme_blue.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_no_css(".white.active")
      expect(page).to have_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_no_css(".white.active")
      expect(page).to have_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end

    # reload したり別ページに遷移した場合、セッションから選択が復元されるはず
    visit item.full_url
    expect(page).to have_css(".accessibility__tool-wrap", count: 2)
    expect(page).to have_css("body[data-ss-theme='#{theme_blue.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_no_css(".white.active")
      expect(page).to have_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_css(".white", text: theme_white.name)
      expect(page).to have_css(".blue", text: theme_blue.name)
      expect(page).to have_css(".black", text: theme_black.name)

      expect(page).to have_no_css(".white.active")
      expect(page).to have_css(".blue.active")
      expect(page).to have_no_css(".black.active")
    end

    within all(".accessibility__tool-wrap")[1] do
      click_on theme_black.name
    end

    expect(page).to have_css("body[data-ss-theme='#{theme_black.class_name}']")
    within all(".accessibility__tool-wrap")[0] do
      expect(page).to have_no_css(".white.active")
      expect(page).to have_no_css(".blue.active")
      expect(page).to have_css(".black.active")
    end
    within all(".accessibility__tool-wrap")[1] do
      expect(page).to have_no_css(".white.active")
      expect(page).to have_no_css(".blue.active")
      expect(page).to have_css(".black.active")
    end
  end
end
