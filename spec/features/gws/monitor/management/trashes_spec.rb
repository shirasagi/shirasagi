require 'spec_helper'

describe "gws_monitor_management_trashes", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:item1) do
    create(
      :gws_monitor_topic, :gws_monitor_deleted, attend_group_ids: [g1.id, g2.id],
      state: 'public', article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end
  let(:item2) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end
  let(:index_path) { gws_monitor_management_trashes_path(site) }
  let(:new_path) { new_gws_monitor_management_trash_path(site) }
  let(:delete_path) { delete_gws_monitor_management_trash_path(site, item1) }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item1
      visit index_path
      expect(page).to have_content(item1.name)
    end

    it "#index not deleted" do
      item2
      visit index_path
      expect(page).to have_no_content(item2.name)
    end
  end

  context "#delete with auth" do
    before { login_gws_user }

    before do
      item1
      item1.create_download_directory(File.dirname(item1.zip_path))
      File.open(item1.zip_path, "w").close
    end

    it "#delete" do
      expect(FileTest.exist?(item1.zip_path)).to be_truthy
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(page).to have_css('#notice', text: '削除しました。')
      expect(FileTest.exist?(item1.zip_path)).to be_falsey
    end
  end
end
