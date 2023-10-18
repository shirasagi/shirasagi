require 'spec_helper'

describe Contact::Apis::ContactsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) do
    contact_groups = 20.times.map do |idx|
      {
        name: "name-#{idx}", contact_group_name: "group_name-#{idx}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        main_state: ((idx == 0) ? "main" : nil)
      }
    end
    create(:contact_group, name: "#{group0.name}/#{unique_id}", contact_groups: contact_groups, order: 1)
  end
  let!(:group2) do
    contact_groups = 20.times.map do |idx|
      {
        name: "name-#{idx}", contact_group_name: "group_name-#{idx}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        main_state: ((idx == 0) ? "main" : nil)
      }
    end
    create(:contact_group, name: "#{group0.name}/#{unique_id}", contact_groups: contact_groups, order: 2)
  end
  let!(:group3) do
    contact_groups = 20.times.map do |idx|
      {
        name: "name-#{idx}", contact_group_name: "group_name-#{idx}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        main_state: ((idx == 0) ? "main" : nil)
      }
    end
    create(:contact_group, name: "#{group0.name}/#{unique_id}", contact_groups: contact_groups, order: 2)
  end

  let!(:index_path) { contact_apis_contacts_path site }

  context "with auth" do
    before { login_cms_user }

    it do
      visit index_path

      within "tbody.items" do
        expect(page).to have_selector("tr[data-id]", count: 50)

        expect(page).to have_css("tr a", text: group0.trailing_name)

        expect(page).to have_css("tr a", text: group1.trailing_name)
        group1.contact_groups.each do |contact_group|
          expect(page).to have_css("tr a", text: contact_group.name)
        end

        expect(page).to have_css("tr a", text: group2.trailing_name)
        group2.contact_groups.each do |contact_group|
          expect(page).to have_css("tr a", text: contact_group.name)
        end

        expect(page).to have_css("tr a", text: group3.trailing_name)
        group3.contact_groups[..9].each do |contact_group|
          expect(page).to have_css("tr a", text: contact_group.name)
        end
      end
      within ".pagination" do
        expect(page).to have_selector(".page", count: 2)
        click_on "2"
      end
      within "tbody.items" do
        expect(page).to have_selector("tr[data-id]", count: 11)

        expect(page).to have_css("tr a", text: group3.trailing_name)
        group3.contact_groups[9..].each do |contact_group|
          expect(page).to have_css("tr a", text: contact_group.name)
        end
      end
    end
  end
end
