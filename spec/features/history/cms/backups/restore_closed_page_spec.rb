require 'spec_helper'

describe "history_cms_backups able to restore only closed page", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:ss_file1) { create_once :ss_file, user: user }
  let(:page_item1) do
    page_item = create(:article_page, cur_node: node, user: user)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "closed"
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
  let(:ss_file2) { create_once :ss_file, user: user }
  let(:page_item2) do
    page_item = create(:article_page, cur_node: node, user: user)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "public"
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
    before { login_cms_user }

    it "#restore at public page" do
      visit page1_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy

      within "[data-id='#{backup_item1.id}']" do
        expect(page).to have_content(I18n.l(backup_item1.data[:updated].in_time_zone, format: :picker))
        click_on I18n.t("ss.links.show")
      end
      expect(current_path).not_to eq sns_login_path

      expect(page).not_to have_link(I18n.t("history.restore"))
    end

    it "#restore at closed page" do
      expect(page_item2.state).to eq "closed"
      expect(page_item2.files.first.state).to eq "closed"

      visit page2_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy

      within "[data-id='#{backup_item2.id}']" do
        expect(page).to have_content(I18n.l(backup_item2.data[:updated].in_time_zone, format: :picker))
        click_on I18n.t("ss.links.show")
      end
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t("history.restore")
      expect(current_path).to eq restore2_path

      click_button I18n.t("history.buttons.restore")
      expect(current_path).to eq show2_path

      click_link I18n.t('ss.links.back')
      expect(current_path).to eq page2_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("first update")).to be_truthy

      expect(page_item2.state).to eq "closed"
      expect(page_item2.files.first.state).to eq "closed"
    end
  end
end
