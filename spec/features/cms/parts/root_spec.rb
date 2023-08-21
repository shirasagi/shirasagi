require 'spec_helper'

describe "cms_parts", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let!(:group1) { create :cms_group, name: unique_id }
  let!(:group2) { create :cms_group, name: unique_id }

  let!(:item1) { create :cms_part, filename: "item1.part.html", group_ids: [group1.id] }
  let!(:item2) { create :cms_part, filename: "item2.part.html", group_ids: [group2.id] }

  let(:contents_path) { cms_contents_path(site) }
  let(:index_path) { cms_parts_path site.id }

  def visit_root_parts
    visit contents_path
    first(".main-navi a", text: I18n.t("cms.part")).click
    expect(current_path).to eq index_path
  end

  context "with admin" do
    before do
      site.group_ids += [group1.id, group2.id]
      site.save!
      login_cms_user
    end

    it "#index" do
      visit contents_path
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.content"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.node"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.page"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.part"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.layout"))
    end

    it "#new" do
      visit_root_parts

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#addon-basic" do
        expect(page).to have_css("dd", text: "sample")
      end
    end

    it "#show" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        click_on item1.name
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: item1.name)
        expect(page).to have_css("dd", text: item1.filename)
      end
    end

    it "#edit" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        click_on item1.name
      end

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#addon-basic" do
        expect(page).to have_css("dd", text: "modify")
        expect(page).to have_css("dd", text: item1.filename)
      end
    end

    it "#delete" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        click_on item1.name
      end

      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".list-items" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
      end
    end
  end

  context "with user1" do
    let(:permissions) { cms_role.permissions.select { |item| item =~ /_private_/ } }
    let(:role) { create :cms_role, name: "role", permissions: permissions, permission_level: 3 }
    let!(:user1) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [group1.id], cms_role_ids: [role.id])
    end

    before do
      site.group_ids += [group1.id, group2.id]
      site.save!
      login_user(user1)
    end

    it "#index" do
      visit contents_path
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.content"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.node"))
      expect(page).to have_no_css(".main-navi a", text: I18n.t("cms.page"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.part"))
      expect(page).to have_css(".main-navi a", text: I18n.t("cms.layout"))
    end

    it "#new" do
      visit_root_parts

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#addon-basic" do
        expect(page).to have_css("dd", text: "sample")
      end
    end

    it "#show" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        click_on item1.name
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: item1.name)
        expect(page).to have_css("dd", text: item1.filename)
      end
    end

    it "#edit" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        click_on item1.name
      end

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within "#addon-basic" do
        expect(page).to have_css("dd", text: "modify")
        expect(page).to have_css("dd", text: item1.filename)
      end
    end

    it "#delete" do
      visit_root_parts

      within ".list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        click_on item1.name
      end

      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      within ".list-items" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
    end
  end
end
