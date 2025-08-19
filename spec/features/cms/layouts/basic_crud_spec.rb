require 'spec_helper'

describe "cms_layouts", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let(:layout_permissions) do
    %w(
      read_private_cms_layouts edit_private_cms_layouts delete_private_cms_layouts
      read_other_cms_layouts edit_other_cms_layouts delete_other_cms_layouts
      edit_cms_ignore_syntax_check
    )
  end
  let!(:role) do
    create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: layout_permissions
  end
  let(:user) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: role.id }
  let!(:part) { create :cms_part_free, html: '<main><span id="test-part"></span></main>' }
  let!(:part_name) { part.filename.sub(/\..*/, '') }

  context "with auth" do
    before { login_user user }

    it "#crud" do
      # new
      visit cms_layouts_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in_code_mirror "item[html]", with: %({{ part "#{part_name}" }})
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::Layout.all.count).to eq 1
      layout = Cms::Layout.all.first
      expect(layout.site_id).to eq site.id
      expect(layout.name).to eq "sample"
      expect(layout.filename).to eq "sample.layout.html"
      expect(layout.html).to eq %({{ part "#{part_name}" }})
      # parts
      expect(layout.parse_parts.size).to eq 1
      expect(layout.parse_parts[part.filename]).to be_present

      # show & edit
      visit cms_layouts_path(site: site)
      click_on layout.name
      expect(page).to have_css("#addon-basic", text: layout.name)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      layout.reload
      expect(layout.site_id).to eq site.id
      expect(layout.name).to eq "modify"
      expect(layout.filename).to eq "sample.layout.html"
      expect(layout.html).to eq %({{ part "#{part_name}" }})
      # parts
      expect(layout.parse_parts.size).to eq 1
      expect(layout.parse_parts[part.filename]).to be_present

      # delete
      visit cms_layouts_path(site: site)
      click_on layout.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { layout.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end

    context 'with descendant layout' do
      let(:node) { create :cms_node }
      let!(:item) { create :cms_layout, filename: "#{node.filename}/name" }

      it "#index" do
        visit cms_layouts_path(site: site)
        expect(page).to have_selector('.list-item[data-id]', count: 0)

        within "form.index-search" do
          select I18n.t('cms.options.node_target.descendant'), from: 's[target]'
          click_on I18n.t('ss.buttons.search')
        end
        expect(page).to have_selector('.list-item[data-id]', count: 1)

        click_link item.name
        expect(page).to have_css("#addon-basic", text: item.name)
        expect(current_path).to eq node_layout_path(site: site.id, cid: node.id, id: item.id)
      end
    end
  end
end
