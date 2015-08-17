require 'spec_helper'

describe "cms_users", dbscope: :example do
  subject(:site) { cms_site }
  subject(:group) { cms_group }
  subject(:item) { create(:cms_test_user, group: group) }
  subject(:index_path) { cms_users_path site.id }
  subject(:new_path) { new_cms_user_path site.id }
  subject(:show_path) { cms_user_path site.id, item }
  subject(:edit_path) { edit_cms_user_path site.id, item }
  subject(:delete_path) { delete_cms_user_path site.id, item }
  subject(:import_path) { import_cms_users_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  it "#index" do
    login_cms_user
    visit index_path
    expect(current_path).not_to eq sns_login_path
  end

  context "with sns user" do
    it "#new" do
      login_cms_user
      visit new_path
      within "form#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        fill_in "item[in_password]", with: "pass"
        check "item[group_ids][]"
        check "item[cms_role_ids][]"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      login_cms_user
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      login_cms_user
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      login_cms_user
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end

  context "with ldap user" do
    it "#new" do
      login_cms_user
      visit new_path
      within "form#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[uid]", with: name
        fill_in "item[ldap_dn]", with: "dc=#{name},dc=city,dc=example,dc=jp"
        check "item[group_ids][]"
        check "item[cms_role_ids][]"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      login_cms_user
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      login_cms_user
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      login_cms_user
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end

  context "import from csv" do
    before(:each) do
      g1 = create(:cms_group, name: "A", order: 10)
      g2 = create(:cms_group, name: "A/B", order: 20)
      g3 = create(:cms_group, name: "A/B/C", order: 30)
      g4 = create(:cms_group, name: "A/B/D", order: 40)
      r1 = create(:cms_role, name: "all")
      r1 = create(:cms_role, name: "edit")
      cms_site.add_to_set(group_ids: [g1.id, g2.id, g3.id, g4.id])
    end

    it "#import" do
      login_cms_user
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv"
        click_button "インポート"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      users = Cms::User.site(cms_site).ne(id: cms_user.id)
      expected_emails = %w(
        import_admin@example.jp
        import_user1@example.jp
        import_user2@example.jp
        import_sys@example.jp
      )
      expected_names = %w(import_admin import_user1 import_user2 import_sys)
      expected_uids = %w(admin user1 user2 sys)
      expected_groups = [ ["A/B/C"], ["A/B/C", "A/B/D"], ["A/B/D"], ["A"] ]
      expected_cms_roles = [ ["all"], ["edit"], ["edit"], ["all", "edit"] ]

      expect(users.map(&:name)).to eq expected_names
      expect(users.map(&:email)).to eq expected_emails
      expect(users.map(&:uid)).to eq expected_uids
      expect(users.map{|u| u.groups.map(&:name)}).to eq expected_groups
      expect(users.map{|u| u.cms_roles.order_by(name: 1).map(&:name)}).to eq expected_cms_roles
    end
  end
end
