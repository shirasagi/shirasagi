require 'spec_helper'

describe "history_cms_logs", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
                group_ids: [cms_group.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path(site: site, cid: node, id: item) }

  subject(:logs_path) { history_cms_logs_path site.id }

  context "attach file upload log" do
    before { login_cms_user }

    it do
      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        ensure_addon_opened "#addon-cms-agents-addons-file"
        ss_upload_file "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
          within "#addon-cms-agents-addons-file" do
            expect(page).to have_css(".file-view", text: "keyvisual.jpg")
            click_on I18n.t("sns.file_attach")
          end
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      item.reload
      expect(item.files.count).to eq 1
      file = item.files.first
      file_url = file.url

      History::Log.all.reorder(created: 1, id: 1).to_a.tap do |histories|
        histories[0].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to be_present
          expect(history.request_id).to be_present
          expect(history.url).to eq sns_login_path
          expect(history.controller).to eq "sns/login"
          expect(history.action).to eq "login"
          expect(history.target_id).to eq cms_user.id.to_s
          expect(history.target_class).to eq "SS::User"
          expect(history.page_url).to be_blank
          expect(history.behavior).to be_blank
          expect(history.ref_coll).to eq "ss_users"
          expect(history.filename).to be_blank
        end
        histories[1].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to be_present
          expect(history.request_id).to be_present
          expect(history.url).to eq edit_path
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "login"
          expect(history.target_id).to eq site.id.to_s
          expect(history.target_class).to eq "Cms::Site"
          expect(history.page_url).to be_blank
          expect(history.behavior).to be_blank
          expect(history.ref_coll).to eq "ss_sites"
          expect(history.filename).to be_blank
        end
        histories[2].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to be_present
          expect(history.request_id).to be_present
          expect(history.url).to eq file_url
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "update"
          expect(history.target_id).to eq file.id.to_s
          expect(history.target_class).to eq file.class.name
          expect(history.page_url).to eq article_page_path(site: site, cid: node, id: item)
          expect(history.behavior).to eq "attachment"
          expect(history.ref_coll).to eq "ss_files"
          expect(history.filename).to be_blank
        end
        histories[3].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to eq histories[2].session_id
          expect(history.request_id).to eq histories[2].request_id
          expect(history.url).to eq file_url
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "update"
          expect(history.target_id).to be_blank
          expect(history.target_class).to be_blank
          expect(history.page_url).to eq article_page_path(site: site, cid: node, id: item)
          expect(history.behavior).to eq "paste"
          expect(history.ref_coll).to eq "ss_files"
          expect(history.filename).to be_blank
        end
        histories[4].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to eq histories[2].session_id
          expect(history.request_id).to eq histories[2].request_id
          expect(history.url).to eq article_page_path(site: site, cid: node, id: item)
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "update"
          expect(history.target_id).to eq item.id.to_s
          expect(history.target_class).to eq item.class.name
          expect(history.page_url).to be_blank
          expect(history.behavior).to be_blank
          expect(history.ref_coll).to eq "cms_pages"
          expect(history.filename).to be_blank
        end
      end
      expect(History::Log.all.count).to eq 5
      expect(History::Log.where(site_id: site.id).count).to eq 4

      visit logs_path
      expect(page).to have_css('.list-item', count: 4)

      visit edit_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        ensure_addon_opened "#addon-cms-agents-addons-file"
        within "#addon-cms-agents-addons-file" do
          page.accept_alert(/#{::Regexp.escape(I18n.t("ss.confirm.in_use"))}/) do
            click_on I18n.t("ss.buttons.delete")
          end
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      History::Log.all.reorder(created: 1, id: 1).to_a.tap do |histories|
        histories[5].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to eq histories[2].session_id
          expect(history.request_id).to be_present
          expect(history.request_id).not_to eq histories[2].request_id
          expect(history.url).to eq file_url
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "destroy"
          expect(history.target_id).to eq file.id.to_s
          expect(history.target_class).to eq file.class.name
          expect(history.page_url).to eq article_page_path(site: site, cid: node, id: item)
          expect(history.behavior).to eq "attachment"
          expect(history.ref_coll).to eq "ss_files"
          expect(history.filename).to be_blank
        end
        histories[6].tap do |history|
          expect(history.user_id).to eq cms_user.id
          expect(history.session_id).to eq histories[2].session_id
          expect(history.request_id).to eq histories[5].request_id
          expect(history.url).to eq article_page_path(site: site, cid: node, id: item)
          expect(history.controller).to eq "article/pages"
          expect(history.action).to eq "update"
          expect(history.target_id).to eq item.id.to_s
          expect(history.target_class).to eq item.class.name
          expect(history.page_url).to be_blank
          expect(history.behavior).to be_blank
          expect(history.ref_coll).to eq "cms_pages"
          expect(history.filename).to be_blank
        end
      end
      expect(History::Log.all.count).to eq 7
      expect(History::Log.where(site_id: site.id).count).to eq 6

      visit logs_path
      expect(page).to have_css('.list-item', count: 6)
    end
  end
end
