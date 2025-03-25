require 'spec_helper'

describe "theme/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
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
      :cms_theme_template, :cms_theme_template_black, cur_site: site, order: 20, state: "public", default_theme: "disabled"
    )
  end

  context "usual case" do
    let!(:part1) { create :accessibility_tool, cur_site: site }
    let!(:part2) { create :accessibility_tool_compat1, cur_site: site }
    let!(:part3) { create :accessibility_tool_compat2, cur_site: site }
    let!(:layout) { create_cms_layout part1, part2, part3 }

    it do
      ::FileUtils.rm_f item.path

      visit item.full_url
      wait_for_all_themes_ready
      expect(page).to have_css(".accessibility__tool-wrap", count: 3)
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
      within all(".accessibility__tool-wrap")[2] do
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
      within all(".accessibility__tool-wrap")[2] do
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
      expect(page).to have_css(".accessibility__tool-wrap", count: 3)
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
      within all(".accessibility__tool-wrap")[2] do
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
      within all(".accessibility__tool-wrap")[2] do
        expect(page).to have_no_css(".#{theme_white.class_name}.active")
        expect(page).to have_no_css(".#{theme_blue.class_name}.active")
        expect(page).to have_css(".#{theme_black.class_name}.active")
      end
    end
  end

  context "special case" do
    let!(:part1) do
      html = <<~HTML
        <div class="accessibility__theme">背景色
          <div data-tool="ss-theme" data-tool-type="button">
            <div class="on-pc">
              <button type="button" class="white">#{theme_white.name}</button>
              <span class="separator">-</span>
              <button type="button" class="blue">#{theme_blue.name}</button>
              <span class="separator">-</span>
              <button type="button" class="black">#{theme_black.name}</button>
            </div>
            <div class="on-mobile">
              <button type="button" class="white">
                <span class="material-icons-outlined" aria-label="#{theme_white.name}" role="img">palette</span>
              </button>
              <button type="button" class="blue">
                <span class="material-icons-outlined" aria-label="#{theme_blue.name}" role="img">palette</span>
              </button>
              <button type="button" class="black">
                <span class="material-icons-outlined" aria-label="#{theme_black.name}" role="img">palette</span>
              </button>
            </div>
          </div>
        </div>
      HTML
      create :cms_part_free, cur_site: site, html: html
    end
    let!(:layout) { create_cms_layout part1 }

    it do
      ::FileUtils.rm_f item.path

      visit item.full_url
      wait_for_all_themes_ready
      expect(page).to have_css(".accessibility__theme", count: 1)

      within ".on-pc" do
        expect(page).to have_css(".#{theme_white.class_name}.active", text: theme_white.name)
        expect(page).to have_css(".#{theme_blue.class_name}:not(.active)", text: theme_blue.name)
        expect(page).to have_css(".#{theme_black.class_name}:not(.active)", text: theme_black.name)
      end
      within ".on-mobile" do
        expect(page).to have_css(".#{theme_white.class_name}.active [aria-label='#{theme_white.name}']")
        expect(page).to have_css(".#{theme_blue.class_name}:not(.active) [aria-label='#{theme_blue.name}']")
        expect(page).to have_css(".#{theme_black.class_name}:not(.active) [aria-label='#{theme_black.name}']")
      end

      within ".on-pc" do
        click_on theme_blue.name
      end

      within ".on-pc" do
        expect(page).to have_css(".#{theme_white.class_name}:not(.active)", text: theme_white.name)
        expect(page).to have_css(".#{theme_blue.class_name}.active", text: theme_blue.name)
        expect(page).to have_css(".#{theme_black.class_name}:not(.active)", text: theme_black.name)
      end
      within ".on-mobile" do
        expect(page).to have_css(".#{theme_white.class_name}:not(.active) [aria-label='#{theme_white.name}']")
        expect(page).to have_css(".#{theme_blue.class_name}.active [aria-label='#{theme_blue.name}']")
        expect(page).to have_css(".#{theme_black.class_name}:not(.active) [aria-label='#{theme_black.name}']")
      end

      within ".on-mobile" do
        click_on theme_black.name
      end

      within ".on-pc" do
        expect(page).to have_css(".#{theme_white.class_name}:not(.active)", text: theme_white.name)
        expect(page).to have_css(".#{theme_blue.class_name}:not(.active)", text: theme_blue.name)
        expect(page).to have_css(".#{theme_black.class_name}.active", text: theme_black.name)
      end
      within ".on-mobile" do
        expect(page).to have_css(".#{theme_white.class_name}:not(.active) [aria-label='#{theme_white.name}']")
        expect(page).to have_css(".#{theme_blue.class_name}:not(.active) [aria-label='#{theme_blue.name}']")
        expect(page).to have_css(".#{theme_black.class_name}.active [aria-label='#{theme_black.name}']")
      end
    end
  end
end
