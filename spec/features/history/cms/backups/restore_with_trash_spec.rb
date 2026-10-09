require 'spec_helper'

describe "history_cms_backups restore with trash", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, filename: "docs", name: "article" }
  let(:file) { create :ss_file, user_id: cms_user.id }
  let(:page_item) do
    page_item = create(:article_page, cur_node: node)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "public"
      page_item.file_ids = [file.id]
      page_item.update
    end
    Timecop.travel(2.days.from_now) do
      page_item.name = "second update"
      page_item.state = "closed"
      page_item.file_ids = []
      page_item.index_name = "second index_name"
      page_item.update
    end
    page_item
  end
  let(:trash_item) { create(:article_page, cur_node: node, name: unique_id, state: 'public') }
  let(:backup_item) { page_item.backups.find { |item| item.data["name"] == "first update" } }
  let(:page_path) { article_page_path site.id, node, page_item }
  let(:show_path) do
    source = ERB::Util.url_encode(page_path)
    history_cms_backup_path site.id, source, backup_item._id
  end
  let(:restore_path) do
    source = ERB::Util.url_encode(page_path)
    history_cms_restore_path site.id, source, backup_item._id
  end

  context "with auth" do
    before do
      trash_item.destroy
    end

    it "#show" do
      login_cms_user to: show_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t("ss.links.back")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(current_path).to eq page_path
    end

    it "#restore" do
      login_cms_user to: page_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy
      expect(basic_values.include?("second index_name")).to be_truthy
      expect(page).to have_no_css('div.file-view', text: file.name)

      page.scroll_to(find("#addon-history-agents-addons-backup"), align: :top)
      ensure_addon_opened "#addon-history-agents-addons-backup"
      within "#addon-history-agents-addons-backup" do
        wait_for_turbo_frame "#addon-history-agents-addons-backup-frame"
        within "[data-id='#{backup_item.id}']" do
          expect(page).to have_content(I18n.l(backup_item.data[:updated].in_time_zone, format: :picker))
          click_on I18n.t("ss.links.show")
        end
      end
      expect(page).to have_content(I18n.l(backup_item.created, format: :picker))
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t("history.restore")
      expect(page).to have_css('dd', text: I18n.l(page_item.updated))
      expect(current_path).to eq restore_path

      click_button I18n.t("history.buttons.restore")
      wait_for_notice I18n.t("history.notice.restored")
      expect(current_path).to eq show_path

      click_link I18n.t("ss.links.back")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(current_path).to eq page_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("first update")).to be_truthy
      expect(basic_values.include?("second index_name")).not_to be_truthy
      expect(page).to have_css('div.file-view', text: file.name)

      expect(Article::Page.count).to eq 1
      item = Article::Page.first
      expect(item.name).to eq "first update"
      expect(item.index_name).to be_nil
      expect(item.state).to eq "closed"
    end
  end
end
