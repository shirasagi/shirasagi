require 'spec_helper'

describe "history_cms_backups able to restore only closed page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page_item1) do
    page_item = create(:article_page, cur_node: node, user: user)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "closed"
      ss_file1 = tmp_ss_file user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      page_item.file_ids = [ss_file1.id]
      page_item.update
    end
    Timecop.travel(2.days.from_now) do
      page_item.name = "second update"
      page_item.state = "public"
      page_item.update
    end
    page_item
  end
  let!(:page_item2) do
    page_item = create(:article_page, cur_node: node, user: user)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "public"
      ss_file2 = tmp_ss_file user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      page_item.file_ids = [ss_file2.id]
      page_item.update
    end
    Timecop.travel(2.days.from_now) do
      page_item.name = "second update"
      page_item.state = "closed"
      page_item.update
    end
    page_item
  end
  let(:backup_item1) { page_item1.backups.find { |item| item.data["name"] == "first update" } }
  let(:backup_item2) { page_item2.backups.find { |item| item.data["name"] == "first update" } }
  let(:page1_path) { article_page_path site.id, node, page_item1 }
  let(:page2_path) { article_page_path site.id, node, page_item2 }
  let(:show1_path) do
    source = ERB::Util.url_encode(page1_path)
    history_cms_backup_path site.id, source, backup_item1._id
  end
  let(:show2_path) do
    source = ERB::Util.url_encode(page2_path)
    history_cms_backup_path site.id, source, backup_item2._id
  end
  let(:restore1_path) do
    source = ERB::Util.url_encode(page1_path)
    history_cms_restore_path site.id, source, backup_item1._id
  end
  let(:restore2_path) do
    source = ERB::Util.url_encode(page2_path)
    history_cms_restore_path site.id, source, backup_item2._id
  end

  context "with auth" do
    it "#restore at public page" do
      login_cms_user to: page1_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy

      page.scroll_to(find("#addon-history-agents-addons-backup"), align: :top)
      ensure_addon_opened "#addon-history-agents-addons-backup"
      within "#addon-history-agents-addons-backup" do
        wait_for_turbo_frame "#addon-history-agents-addons-backup-frame"
        within "[data-id='#{backup_item1.id}']" do
          expect(page).to have_content(I18n.l(backup_item1.data[:updated].in_time_zone, format: :picker))
          click_on I18n.t("ss.links.show")
        end
      end
      expect(current_path).not_to eq sns_login_path

      expect(page).not_to have_link(I18n.t("history.restore"))
    end

    it "#restore at closed page" do
      expect(page_item2.state).to eq "closed"
      expect(page_item2.files.first.state).to eq "closed"

      login_cms_user to: page2_path
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy

      page.scroll_to(find("#addon-history-agents-addons-backup"), align: :top)
      ensure_addon_opened "#addon-history-agents-addons-backup"
      within "#addon-history-agents-addons-backup" do
        wait_for_turbo_frame "#addon-history-agents-addons-backup-frame"
        within "[data-id='#{backup_item2.id}']" do
          expect(page).to have_content(I18n.l(backup_item2.data[:updated].in_time_zone, format: :picker))
          click_on I18n.t("ss.links.show")
        end
      end
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t("history.restore")
      expect(current_path).to eq restore2_path

      click_button I18n.t("history.buttons.restore")
      expect(current_path).to eq show2_path

      click_link I18n.t('ss.links.back')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(current_path).to eq page2_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("first update")).to be_truthy

      expect(page_item2.state).to eq "closed"
      expect(page_item2.files.first.state).to eq "closed"
    end
  end
end
