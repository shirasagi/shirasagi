require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:user1) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: admin.cms_role_ids }

  let!(:part) { create :cms_part_free, html: '<div id="part" class="part"><br><br><br>free html part<br><br><br></div>' }
  let(:layout_html) do
    <<~HTML.freeze
      <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimum-scale=1.0,maximum-scale=2.0">
      </head>
      <body>
        <br><br><br>
        {{ part "#{part.filename.sub(/\..*/, '')}" }}
        <div id="main" class="page">
          {{ yield }}
        </div>
      </body>
      </html>
    HTML
  end
  let!(:layout) { create :cms_layout, cur_site: site, html: layout_html }

  let!(:node) { create(:article_node_page, cur_site: site, layout: layout) }
  let(:item_html) do
    <<~HTML
      <p class=\"page-body\">#{unique_id}</p>
    HTML
  end
  let!(:item) do
    create(
      :article_page, cur_site: site, cur_node: node, layout: layout, html:
      item_html, state: "closed", group_ids: admin.group_ids)
  end

  let(:request_comment) { "comment-#{unique_id}" }
  let(:approve_comment) { "approve-#{unique_id}" }

  it do
    login_user user1
    visit cms_preview_path(site: site, path: item.preview_path)
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames

    within ".ss-preview-wrap-column-edit-mode" do
      wait_for_event_fired("ss:previewDialogOpened") do
        click_on I18n.t("workflow.buttons.approve")
      end
    end
    within ".ss-preview-workflow-wizard" do
      fill_in "workflow[comment]", with: request_comment
      wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
    end
    within_cbox do
      expect(page).to have_content(admin.long_name)
      wait_for_cbox_closed { click_on admin.long_name }
    end
    within ".ss-preview-workflow-wizard" do
      expect(page).to have_css("[data-id='1,#{admin.id}']", text: admin.long_name)
      click_on I18n.t("workflow.buttons.request")
    end
    expect(page).to have_css(".ss-preview-workflow-notice", text: "申請中です。")

    item.reload
    expect(item.workflow_state).to eq "request"
    expect(item.workflow_comment).to eq request_comment
    expect(item.workflow_approvers).to include(
      { level: 1, user_id: admin.id, editable: be_blank, state: "request", comment: be_blank }
    )
    expect(item.state).to eq "closed"

    login_user admin
    visit cms_preview_path(site: site, path: item.preview_path)
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames
    expect(page).to have_css(".ss-preview-workflow-notice", text: "承認依頼が届いています。")
    within ".ss-preview-wrap-column-edit-mode" do
      wait_for_event_fired("ss:previewDialogOpened") do
        click_on I18n.t("workflow.buttons.approve")
      end
    end
    within "#ss-preview-dialog-frame" do
      fill_in "comment", with: approve_comment
      click_on I18n.t("workflow.buttons.approve")
    end

    # sleep 60
    expect(page).to have_css(".ss-preview-workflow-state", text: I18n.t("workflow.state.approve"))

    item.reload
    expect(item.workflow_state).to eq "approve"
    expect(item.workflow_comment).to eq request_comment
    expect(item.workflow_approvers).to include(
      { level: 1, user_id: admin.id, editable: be_blank, state: "approve", comment: approve_comment,
        file_ids: be_blank, created: be_within(5.minutes).of(Time.zone.now) }
    )
    expect(item.state).to eq "public"
  end
end
