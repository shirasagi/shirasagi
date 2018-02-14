require 'spec_helper'

describe "gws_monitor_management_admins", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:item1) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item1
      visit gws_monitor_management_admins_path(site)
      expect(page).to have_content(item1.name)
      expect(page).to have_content('回答状況(1/2)')
    end

    it "#edit" do
      visit edit_gws_monitor_management_admin_path(site, item1)
      expect(page).to have_content('基本情報')
    end

    it "#show" do
      visit gws_monitor_management_admin_path(site, item1)
      expect(page).to have_content(item1.name)
    end
  end
end
