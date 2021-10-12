require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, filename: "docs", name: "article" }
  let(:item) { create :article_page, cur_node: node }
  let(:edit_path) { edit_article_page_path site, node, item }

  let(:today) { Time.zone.today }
  let(:hours_and_minutes) { (0..23).map { |h| [[h, 0],[h, 30]] }.flatten(1) }
  let(:times) { hours_and_minutes.map { |h, m| format("%02d:%02d", h, m) } }

  before { login_cms_user }

  context "release plan" do
    it "release_date" do
      visit edit_path
      ensure_addon_opened('#addon-cms-agents-addons-release_plan')
      within "#addon-cms-agents-addons-release_plan" do
        first('[name="item[release_date]"]').click
      end
      within first(".xdsoft_datetimepicker", visible: true) do
        within first(".xdsoft_scroller_box", visible: true) do
          times.each do |time|
            expect(page).to have_css(".xdsoft_time", text: time)
          end
        end
        within first(".xdsoft_calendar", visible: true) do
          expect(page).to have_css(".xdsoft_today", text: today.day)
          first(".xdsoft_today").click
        end
      end
      expect(first('[name="item[release_date]"]').value).to start_with(today.strftime("%Y/%m/%d"))
    end

    it "close_date" do
      visit edit_path
      ensure_addon_opened('#addon-cms-agents-addons-release_plan')
      within "#addon-cms-agents-addons-release_plan" do
        first('[name="item[close_date]"]').click
      end
      within first(".xdsoft_datetimepicker", visible: true) do
        within first(".xdsoft_scroller_box", visible: true) do
          times.each do |time|
            expect(page).to have_css(".xdsoft_time", text: time)
          end
        end
        within first(".xdsoft_calendar", visible: true) do
          expect(page).to have_css(".xdsoft_today", text: today.day)
          first(".xdsoft_today").click
        end
      end
      expect(first('[name="item[close_date]"]').value).to start_with(today.strftime("%Y/%m/%d"))
    end
  end
end
