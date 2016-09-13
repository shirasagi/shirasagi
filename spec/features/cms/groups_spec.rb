require 'spec_helper'

describe "cms_groups", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { cms_group }
  let(:index_path) { cms_groups_path site.id }
  let(:new_path) { new_cms_group_path site.id }
  let(:show_path) { cms_group_path site.id, item }
  let(:edit_path) { edit_cms_group_path site.id, item }
  let(:delete_path) { delete_cms_group_path site.id, item }
  let(:import_path) { import_cms_groups_path site.id }

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
        fill_in "item[name]", with: "cms_group/sample"
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
        fill_in "item[name]", with: "cms_group/modify"
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
  end

  context "import from csv" do
    before(:each) do
      tel   = "000-000-0000"
      email = "sys@example.jp"
      g1 = create(:cms_group, name: "A", order: 10, contact_tel: tel, contact_fax: tel, contact_email: email)
      cms_site.add_to_set(group_ids: [g1.id])
    end

    it "#import" do
      login_cms_user
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/group/cms_groups_1.csv"
        click_button "インポート"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      groups = Cms::Group.site(cms_site).ne(id: cms_group.id)
      expected_names = %w(A A/B A/B/C A/B/C/D A/E A/E/F A/E/G)
      expected_orders = %w(10 20 30 40 50 60 70).map(&:to_i)
      expected_contact_tels = %w(1 2 3 4 5 6 7).fill("000-000-0000")
      expected_contact_faxs = %w(1 2 3 4 5 6 7).fill("000-000-0000")
      expected_contact_emails = %w(1 2 3 4 5 6 7).fill("sys@example.jp")

      expect(groups.map(&:name)).to eq expected_names
      expect(groups.map(&:order)).to eq expected_orders
      expect(groups.map(&:contact_tel)).to eq expected_contact_tels
      expect(groups.map(&:contact_fax)).to eq expected_contact_faxs
      expect(groups.map(&:contact_email)).to eq expected_contact_emails
    end
  end

  context "disable group and edit it" do
    let(:group_name) { unique_id }
    let!(:group) { create(:cms_group, name: "#{cms_group.name}/#{group_name}", order: 100) }
    let(:expiration_date) { Time.zone.at((Time.zone.now - 1.day).to_date.to_i) }
    let(:contact_tel) { unique_id }

    before do
      login_cms_user
    end

    it do
      visit index_path

      click_on group_name
      click_on I18n.t("views.links.edit")

      fill_in "item[expiration_date]", with: expiration_date.strftime("%Y/%m/%d %H:%M")
      click_on I18n.t("views.button.save")

      group.reload
      expect(group.expiration_date).to eq expiration_date

      visit index_path
      expect(page).not_to have_css(".expandable", text: group_name)

      select I18n.t("views.options.state.all"), from: "s[state]"
      click_on I18n.t('views.button.search')

      expect(page).to have_css(".expandable", text: group_name)

      click_on group_name
      click_on I18n.t("views.links.edit")

      fill_in "item[contact_tel]", with: contact_tel
      click_on I18n.t("views.button.save")

      group.reload
      expect(group.contact_tel).to eq contact_tel
    end
  end
end
