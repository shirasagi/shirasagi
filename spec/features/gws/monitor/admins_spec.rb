require 'spec_helper'

describe "gws_monitor_admins", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
  let(:item1) do
    create(
      :gws_monitor_topic, cur_site: site, cur_user: user,
      attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      file_ids: [ file.id ], answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item1
      visit gws_monitor_admins_path(site)
      expect(page).to have_content(item1.name)
      expect(page).to have_content("#{I18n.t('gws/monitor.topic.answer_state')}(1/2)")
    end

    it "#new" do
      visit new_gws_monitor_admin_path(site)
      expect(page).to have_content(I18n.t("ss.basic_info"))
    end

    it "#copy" do
      item1.reload
      expect(item1.file_ids).to have(1).items
      file.reload
      expect(file.owner_item_id).to eq item1.id
      expect(file.owner_item_type).to eq item1.class.name

      visit gws_monitor_admins_path(site)
      click_on item1.name

      click_on I18n.t("ss.links.copy")
      within "form#item-form" do
        fill_in "item[name]", with: "copy_sample"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(current_path).not_to eq copy_gws_monitor_admin_path(item1.id,site)
      expect(page).to have_content("copy_sample")

      expect(Gws::Monitor::Topic.all.count).to eq 2
      copy_topic = Gws::Monitor::Topic.all.ne(id: item1.id).first
      expect(copy_topic.name).to eq "copy_sample"
      expect(copy_topic.file_ids).to have(1).items
      copy_topic.files.first.tap do |copy_file|
        expect(copy_file.id).not_to eq file.id
        expect(copy_file.owner_item_id).to eq copy_topic.id
        expect(copy_file.owner_item_type).to eq copy_topic.class.name
      end

      # fileの所有者に変化がないことを確認する
      file.reload
      expect(file.owner_item_id).to eq item1.id
      expect(file.owner_item_type).to eq item1.class.name
    end
  end
end
