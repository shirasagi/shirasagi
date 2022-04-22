require 'spec_helper'

describe "workflow_remind", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:user1) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let!(:user2) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page1) { create :article_page, cur_site: site, cur_node: node, state: "closed" }
  let!(:page2) { create :article_page, cur_site: site, cur_node: node, state: "closed" }

  before do
    # テストの再現性を高めるために、ミリ秒部を 0 クリアするし、page2 の更新日時を page1 と同じにする
    page1.set(updated: page1.updated.change(usec: 0).utc)
    page2.set(updated: page1.updated.change(usec: 0).utc)

    # page1 だけ承認申請
    page1.workflow_user_id = user1.id
    page1.workflow_state = "request"
    # 2 人に申請を送り、1 人は承認済み。もう一人は未承認。
    page1.workflow_approvers = [
      { level: 1, user_id: user2.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: "" }
    ]
    page1.workflow_required_counts = [ false ]
    page1.save!
  end

  context "when approve_remind_state is disabled" do
    before do
      site.approve_remind_state = nil
      site.approve_remind_later = "1.day"
      site.save!
    end

    it do
      Timecop.freeze(page1.updated + 1.day) do
        login_cms_user
        visit article_pages_path(site: site, cid: node)

        expect(page).to have_css(".list-item[data-id='#{page1.id}'] .state-request", text: I18n.t("ss.state.request"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}'] .state-edit", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".workflow-remind")
      end
      Timecop.freeze(page1.updated + 1.day + 1.second) do
        login_cms_user
        visit article_pages_path(site: site, cid: node)

        expect(page).to have_css(".list-item[data-id='#{page1.id}'] .state-request", text: I18n.t("ss.state.request"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}'] .state-edit", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".workflow-remind")
      end
    end
  end

  context "when approve_remind_state is enabled" do
    before do
      site.mypage_domain = unique_domain
      site.approve_remind_state = "enabled"
      site.approve_remind_later = "1.day"
      site.save!
    end

    it do
      Timecop.freeze(page1.updated + 1.day) do
        login_cms_user
        visit article_pages_path(site: site, cid: node)

        expect(page).to have_css(".list-item[data-id='#{page1.id}'] .state-request", text: I18n.t("ss.state.request"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}'] .state-edit", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".workflow-remind")
      end
      Timecop.freeze(page1.updated + 1.day + 1.second) do
        login_cms_user
        visit article_pages_path(site: site, cid: node)

        "#{I18n.t("ss.state.request")}#{I18n.t("workflow.state_remind_suffix")}".tap do |text|
          expect(page).to have_css(".list-item[data-id='#{page1.id}'] .state-request-remind", text: text)
        end
        expect(page).to have_css(".list-item[data-id='#{page2.id}'] .state-edit", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_css(".workflow-remind", text: I18n.t("workflow.notice.content_remind.head"))
      end
    end
  end
end
