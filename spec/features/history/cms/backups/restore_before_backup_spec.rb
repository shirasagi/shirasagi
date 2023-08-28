require 'spec_helper'

describe "history_cms_backups restore", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:file1) { create :ss_file, user_id: cms_user.id }
  let(:file2) { create :ss_file, user_id: cms_user.id }
  let(:file3) { create :ss_file, user_id: cms_user.id }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "video", order: 1)
  end
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }
  let(:page_item) do
    page_item = create(:article_page, cur_node: node, form: form)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "public"
      page_item.file_ids = [file1.id]
      page_item.column_values = [
        column1.value_type.new(column: column1, file_id: file2.id, file_label: file2.humanized_name),
        column2.value_type.new(column: column2, value: unique_id * 2, file_ids: [ file3.id ])
      ]
      page_item.update
    end
    Timecop.travel(2.days.from_now) do
      page_item.name = "second update"
      page_item.state = "closed"
      page_item.file_ids = []
      page_item.index_name = "second index_name"
      page_item.column_values = [
        column1.value_type.new(column: column1),
        column2.value_type.new(column: column2, value: unique_id * 2)
      ]
      page_item.update
    end
    page_item
  end
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
    before { login_cms_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t("ss.links.show")
      expect(current_path).to eq page_path
    end

    it "#restore" do
      visit page_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("second update")).to be_truthy
      expect(basic_values.include?("second index_name")).to be_truthy
      expect(page).to have_no_css('div.file-view', text: file1.name)
      expect(page).to have_no_css('div.file-view', text: file2.name)
      expect(page).to have_no_css('div.file-view', text: file3.name)

      click_link I18n.t('history.compare_before_state')
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('th', text: page_item.t(:name))
      expect(page).to have_css('th', text: page_item.t(:state))
      expect(page).to have_css('th', text: page_item.t(:file_ids))
      expect(page).to have_css('th', text: page_item.t(:index_name))
      expect(page).to have_no_css('th', text: page_item.t(:column_values))
      expect(page).to have_css('td', text: column1.name)
      expect(page).to have_css('td', text: column2.name)

      click_link I18n.t('history.restore')
      expect(current_path).to eq restore_path

      click_button I18n.t('history.buttons.restore')
      expect(current_path).to eq show_path

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.class_name).to eq "History::Backup::RestoreJob"
        expect(log.args.first).to eq backup_item.id.to_s
      end

      expect(SS::Task.count).to eq 1
      SS::Task.first.tap do |task|
        expect(task.name).to eq "cms_pages:#{page_item.id}"
        expect(task.state).to eq "completed"
      end

      click_link I18n.t('ss.links.show')
      expect(current_path).to eq page_path

      basic_values = page.all("#addon-basic dd").map(&:text)
      expect(basic_values.index("first update")).to be_truthy
      expect(basic_values.include?("second index_name")).not_to be_truthy
      expect(page).to have_css('div.file-view', text: file1.name)
      expect(page).to have_css('div.file-view', text: file2.name)
      expect(page).to have_css('div.file-view', text: file3.name)
    end
  end
end
