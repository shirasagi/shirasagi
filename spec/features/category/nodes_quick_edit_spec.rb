require 'spec_helper'

describe "category_nodes_base", type: :feature, dbscope: :example, js: :true do 
  let!(:site) { cms_site }
  let!(:node) { create :cms_node }
  let(:index_path) { category_nodes_path site.id, node }
  let!(:item) { create :category_node_page, name: "sample", filename: "#{node.filename}/name", order: 10, site: site }
  let(:quick_edit_path) { quick_edit_category_nodes_path site.id, node }

  context "check quick edit" do
    before { login_cms_user }

    it "quick edit" do
      visit index_path
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css("a", text: "tune")
      click_link "tune"
      wait_for_js_ready
      expect(page).to have_css(".quick-edit-grid")

      within ".quick-edit-grid" do
        expect(page).to have_css("tr[data-id='#{item.id}']")

        within "tr[data-id='#{item.id}']" do
          fill_in "name", with: "quick edit name"
          page.execute_script("document.querySelector('input[name=\"name\"]').blur()")
          expect(page).to have_css(".error-messages", text: I18n.t("ss.notice.saved"))
          page.execute_script("$('.error-messages').text('')")

          fill_in "index_name", with: "quick edit index_name"
          page.execute_script("document.querySelector('input[name=\"index_name\"]').blur()")
          expect(page).to have_css(".error-messages", text: I18n.t("ss.notice.saved"))
          page.execute_script("$('.error-messages').text('')")

          fill_in "order", with: "11"
          page.execute_script("document.querySelector('input[name=\"order\"]').blur()")
          expect(page).to have_css(".error-messages", text: I18n.t("ss.notice.saved"))
          page.execute_script("$('.error-messages').text('')")
        end
      end

      visit quick_edit_path
      expect(page).to have_css(".quick-edit-grid")
      within ".quick-edit-grid" do
        expect(page).to have_css("tr[data-id='#{item.id}']")
        within "tr[data-id='#{item.id}']" do
          expect(find("input[name='name']").value).to eq "quick edit name"
          expect(find("input[name='index_name']").value).to eq "quick edit index_name"
          expect(find("input[name='order']").value).to eq "11"
        end
      end
    end
  end

  context "concurrent quick edit to test optimistic lock" do
    let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
    let!(:user1) { create :cms_test_user, cms_role_ids: cms_user.cms_role_ids, group_ids: [ group1.id ] }
    let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
    let!(:user2) { create :cms_test_user, cms_role_ids: cms_user.cms_role_ids, group_ids: [ group2.id ] }

    it "allows only one user to save changes" do
      window1 = open_new_window
      within_window window1 do
        login_user user1
        visit index_path
        expect(page).to have_css(".content-navi-refresh", text: "refresh")
        click_link "tune"
        wait_for_ajax

        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            fill_in "name", with: "user1 name"
          end
        end
      end

      window2 = open_new_window
      within_window window2 do
        login_user user2
        visit index_path
        expect(page).to have_css(".content-navi-refresh", text: "refresh")
        click_link "tune"
        wait_for_ajax
        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            fill_in "name", with: "user2 name"
            page.execute_script("document.querySelector('input[name=\"name\"]').blur()")
            expect(page).to have_content(I18n.t("ss.notice.saved"))
          end
        end
      end

      within_window window1 do
        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            page.execute_script("document.querySelector('input[name=\"name\"]').blur()")
            expect(page).to have_content(I18n.t("errors.messages.invalid_updated"))
          end
        end

      end

      # Giving it a 2nd try to make sure that user 2 can still make updates.

      within_window window2 do
        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            fill_in "name", with: "user2 name updated"
            page.execute_script("document.querySelector('input[name=\"name\"]').blur()")
            expect(page).to have_content(I18n.t("ss.notice.saved"))
          end
        end
      end

      # making sure in both session if the value is updated properly

      within_window window1 do
        visit quick_edit_path
        expect(page).to have_css(".quick-edit-grid")
        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            expect(find("input[name='name']").value).to eq "user2 name updated"
          end
        end
      end

      within_window window2 do
        visit quick_edit_path
        expect(page).to have_css(".quick-edit-grid")
        within ".quick-edit-grid" do
          within "tr[data-id='#{item.id}']" do
            expect(find("input[name='name']").value).to eq "user2 name updated"
          end
        end
      end

      window1.close
      window2.close
    end
  end

  context "a user with restricted permissions" do
    let(:permissions) { %w(read_other_cms_nodes read_private_cms_nodes edit_private_cms_nodes) }
    let!(:role) { create :cms_role, cur_site: site, permissions: permissions }
    let!(:group) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
    let!(:user) { create :cms_test_user, cms_role_ids: [ role.id ], group_ids: [ group.id ] }

    before do
      node.add_to_set(group_ids: group.id)
      login_user user
    end

    it do
      visit index_path
      expect(page).to have_css(".content-navi-refresh", text: "refresh")
      click_link "tune"

      within ".quick-edit-grid" do
        within "tr[data-id='#{item.id}']" do
          fill_in "name", with: unique_id
        end
      end
      page.execute_script("document.querySelector('input[name=\"name\"]').blur()")

      within ".quick-edit-grid" do
        within "tr[data-id='#{item.id}']" do
          expect(page).to have_content(I18n.t("errors.messages.auth_error"))
        end
      end
    end
  end
end
