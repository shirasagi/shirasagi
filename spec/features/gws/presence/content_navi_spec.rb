require 'spec_helper'

describe 'gws_presence_content_navi', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:all_groups_path) { gws_presence_users_path site }
  let(:custom_group_path) { gws_presence_custom_group_users_path(site, custom_group) }
  let!(:group1) { create :gws_group, name: "#{site.name}/group1" }
  let!(:group2) { create :gws_group, name: "#{site.name}/group1/group2" }

  before { login_gws_user }

  describe 'display' do
    context 'all users' do
      before { visit all_groups_path }

      it do
        within 'div.tree-groups' do
          expect(find('td', text: site.trailing_name)).to be_visible
          expect(find('td', text: group1.trailing_name)).to be_visible
          expect(find('td', text: group2.trailing_name)).not_to be_visible

          find('button.expand-all').click
          wait_for_js_ready
          expect(find('td', text: site.trailing_name)).to be_visible
          expect(find('td', text: group1.trailing_name)).to be_visible
          expect(find('td', text: group2.trailing_name)).to be_visible

          find('button.collapse-all').click
          wait_for_js_ready
          expect(find('td', text: site.trailing_name)).to be_visible
          expect(find('td', text: group1.trailing_name)).not_to be_visible
          expect(find('td', text: group2.trailing_name)).not_to be_visible
        end
      end
    end

    context 'custom group' do
      let!(:custom_group) { create :gws_custom_group, name: "custom_group" }

      before { visit custom_group_path }

      it do
        within 'div.tree-groups' do
          expect(find('td', text: site.trailing_name)).to be_visible
          expect(find('td', text: group1.trailing_name)).to be_visible
          expect(find('td', text: group2.trailing_name)).not_to be_visible
        end

        within 'div.custom-groups' do
          expect(find('td', text: custom_group.name)).to be_visible
        end
      end
    end

    context 'click group name' do
      let!(:group3) { create :gws_group, name: "#{site.name}/group3" }
      let!(:group4) { create :gws_group, name: "#{site.name}/group3/group4" }

      before { visit all_groups_path }

      it 'should display only selected group tree' do
        within 'div.tree-groups' do
          find('td', text: group1.trailing_name).find('img').click
          wait_for_js_ready
          find('td', text: group3.trailing_name).find('img').click
          wait_for_js_ready

          expect(find('td', text: group2.trailing_name)).to be_visible
          expect(find('td', text: group4.trailing_name)).to be_visible

          click_link group2.trailing_name
          wait_for_js_ready

          expect(find('td', text: group2.trailing_name)).to be_visible
          expect(find('td', text: group4.trailing_name)).not_to be_visible
        end
      end
    end
  end

  describe 'sort order' do
    let!(:group3) { create :gws_group, name: "#{site.name}/group1/group3", order: 2 }
    let!(:group4) { create :gws_group, name: "#{site.name}/group1/group4", order: 1 }
    let!(:group5) { create :gws_group, name: "#{site.name}/group1/group5", order: 1 }

    before { visit all_groups_path }

    it do
      within 'div.tree-groups' do
        find('td', text: group1.trailing_name).find('img').click
        wait_for_js_ready
        expect(all('tr[data-depth="2"]')[0].text).to eq group2.trailing_name
        expect(all('tr[data-depth="2"]')[1].text).to eq group4.trailing_name
        expect(all('tr[data-depth="2"]')[2].text).to eq group5.trailing_name
        expect(all('tr[data-depth="2"]')[3].text).to eq group3.trailing_name
      end
    end
  end
end
