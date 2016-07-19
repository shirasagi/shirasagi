require 'spec_helper'

describe "ezine_members" do
  subject(:site) { cms_site }
  subject(:node) { create_once :ezine_node_page }
  subject(:item) { Ezine::Member.last }
  subject(:index_path) { ezine_members_path site.id, node }
  subject(:new_path) { new_ezine_member_path site.id, node }
  subject(:show_path) { ezine_member_path site.id, node, item }
  subject(:edit_path) { edit_ezine_member_path site.id, node, item }
  subject(:delete_path) { delete_ezine_member_path site.id, node, item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[email]", with: "sample@example.jp"
        find("input[name='item[email_type]'][value='text']").set(true) #choose "テキスト版"
        find("input[name='item[state]'][value='enabled']").set(true)   #choose "配信する"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        find("input[name='item[email_type]'][value='html']").set(true) #choose "HTML版"
        find("input[name='item[state]'][value='disabled']").set(true)  #choose "配信しない"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end

    context "with column" do
      before do
        @column = create(:ezine_column, node: node, name: "text", input_type: "text_field", state: "public")
      end

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[email]", with: "sample2@example.jp"
          find("input[name='item[email_type]'][value='text']").set(true) #choose "テキスト版"
          find("input[name='item[state]'][value='enabled']").set(true)   #choose "配信する"
          fill_in "item[in_data][#{@column.id}]", with: "text"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end
  end
end
