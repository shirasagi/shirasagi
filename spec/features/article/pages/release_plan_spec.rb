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

        visit edit_article_page_path(site: site, cid: node, id: branch)
        within "form#item-form" do
          ensure_addon_opened('#addon-cms-agents-addons-release_plan')
          within "#addon-cms-agents-addons-release_plan" do
            fill_in_datetime "item[close_date]", with: close_date
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        branch.reload
        expect(branch.state).to eq "closed"
        expect(branch.release_date).to be_blank
        expect(branch.close_date).to eq close_date

        item.reload
        expect(item.state).to eq "public"
        expect(item.release_date).to be_blank
        expect(item.close_date).to be_blank

        expect do
          visit edit_article_page_path(site: site, cid: node, id: branch)
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t("ss.notice.saved")
        end.to output.to_stdout

        expect { branch.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        item.reload
        expect(item.state).to eq "closed"
        expect(item.release_date).to be_blank
        expect(item.close_date).to be_present
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
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          find("tr[data-id='1,#{cms_user.id}'] input[type=checkbox]").click
          wait_cbox_close { click_on I18n.t("workflow.search_approvers.select") }
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)
        expect(page).to have_css("#workflow_route", text: I18n.t("workflow.restart_workflow"))

        expect { branch.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        item.reload
        expect(item.state).to eq "closed"
        expect(item.release_date).to be_blank
        expect(item.close_date).to be_present
      end
    end
  end
end
