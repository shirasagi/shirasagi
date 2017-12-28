require 'spec_helper'

describe "gws_monitor_answers", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:r1) { create(:gws_role_admin) }
  let(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: [r1.id]) }
  let(:item1) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end
  let(:item2) do
    create(
      :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open',
      spec_config: 'other_groups_and_contents', answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end

  context "with auth" do
    before { login_user u1 }

    it "#index display only my group" do
      item1
      visit gws_monitor_answers_path(site)
      expect(page).to have_content(item1.name)
      expect(page).to have_content('回答状況(1/1)')
    end

    it "#index display all groups" do
      item2
      visit gws_monitor_answers_path(site)
      expect(page).to have_content(item2.name)
      expect(page).to have_content('回答状況(1/2)')
    end
  end
end
