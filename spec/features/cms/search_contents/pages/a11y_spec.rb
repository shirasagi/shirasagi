require 'spec_helper'

describe "cms_search_contents_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:page1) do
    # アクセシビリティ違反なし
    create :cms_page, cur_site: site, syntax_check_result_checked: now, syntax_check_result_violation_count: 0
  end
  let!(:page2) do
    # アクセシビリティ違反あり
    create :cms_page, cur_site: site, syntax_check_result_checked: now, syntax_check_result_violation_count: 1
  end
  let!(:page3) do
    # アクセシビリティ違反を未チェック
    create :cms_page, cur_site: site
  end

  describe "#search_syntax_check_violation" do
    context "when 'both' is selected" do
      it do
        login_cms_user to: cms_search_contents_pages_path(site: site)

        within "form.search-pages" do
          choose I18n.t("cms.options.search_syntax_check_violation.both")

          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item", count: 3)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: page2.name)
        expect(page).to have_css(".list-item[data-id='#{page3.id}']", text: page3.name)
      end
    end

    context "when 'have' is selected" do
      it do
        login_cms_user to: cms_search_contents_pages_path(site: site)

        within "form.search-pages" do
          choose I18n.t("cms.options.search_syntax_check_violation.have")

          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item", count: 1)
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: page2.name)
      end
    end

    context "when 'not_have' is selected" do
      it do
        login_cms_user to: cms_search_contents_pages_path(site: site)

        within "form.search-pages" do
          choose I18n.t("cms.options.search_syntax_check_violation.not_have")

          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: page1.name)
        expect(page).to have_css(".list-item[data-id='#{page3.id}']", text: page3.name)
      end
    end
  end
end
