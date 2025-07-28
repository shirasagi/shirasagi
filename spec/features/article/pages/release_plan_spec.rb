require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }

  before { login_cms_user }

  context "release plan" do
    let(:item) { create :article_page, cur_site: site, cur_node: node }
    let(:edit_path) { edit_article_page_path site, node, item }

    let(:today) { Time.zone.today }
    let(:hours_and_minutes) { (0..23).flat_map { |h| [[h, 0], [h, 30]] } }
    let(:times) { hours_and_minutes.map { |h, m| format("%02d:%02d", h, m) } }

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

  context "branch page" do
    let!(:item) { create :article_page, cur_site: site, cur_node: node, state: "public" }
    let!(:branch) do
      Cms::Page.find(item.id).then do |item|
        item.cur_site = site
        item.cur_node = node
        item.cur_user = cms_user
        branch = item.new_clone
        branch.master = item
        branch.save!

        Cms::Page.find(branch.id)
      end
    end

    # ユースケース: 「公開終了日時(予約)」が過去日に設定された差し替えページを公開保存した場合
    context "when close date is past on branch" do
      let(:now) { Time.zone.now.change(sec: 0) }
      # past day
      let(:close_date) { now - 1.day }

      it do
        expect(branch.state).to eq "closed"
        expect(branch.release_date).to be_blank
        expect(branch.close_date).to be_blank

        expect(item.state).to eq "public"
        expect(item.release_date).to be_blank
        expect(item.close_date).to be_blank

        Timecop.freeze(now) do
          visit edit_article_page_path(site: site, cid: node, id: branch)
          within "form#item-form" do
            ensure_addon_opened('#addon-cms-agents-addons-release_plan')
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime "item[close_date]", with: close_date
            end

            click_on I18n.t("ss.buttons.draft_save")
          end
        end

        message = I18n.t("errors.messages.greater_than", count: I18n.l(now))
        message = I18n.t("errors.format", attribute: Cms::Page.t(:close_date), message: message)
        expect(page).to have_css("#errorExplanation", text: message)
      end
    end

    # ユースケース: 「公開終了日時(予約)」が過去日に設定された差し替えページを承認依頼を経て公開した場合
    context "when close date is past on branch through application" do
      let(:now) { Time.zone.now.change(sec: 0) }
      # past day
      let(:close_date) { now - 1.day }
      let(:workflow_comment) { "workflow_comment-#{unique_id}" }
      let(:approve_comment) { "approve_comment-#{unique_id}" }

      it do
        expect(branch.state).to eq "closed"
        expect(branch.release_date).to be_blank
        expect(branch.close_date).to be_blank

        expect(item.state).to eq "public"
        expect(item.release_date).to be_blank
        expect(item.close_date).to be_blank

        visit edit_article_page_path(site: site, cid: node, id: branch)
        within "form#item-form" do
          ensure_addon_opened('#addon-cms-agents-addons-release_plan')
          within "#addon-cms-agents-addons-release_plan" do
            fill_in_datetime "item[close_date]", with: close_date
          end

          click_on I18n.t("ss.buttons.draft_save")
        end

        message = I18n.t("errors.messages.greater_than", count: I18n.l(now))
        message = I18n.t("errors.format", attribute: Cms::Page.t(:close_date), message: message)
        expect(page).to have_css("#errorExplanation", text: message)
      end
    end
  end
end
