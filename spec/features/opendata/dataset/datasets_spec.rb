require 'spec_helper'

describe "opendata_datasets", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let!(:node_search) { create_once :opendata_node_search_dataset }
  let(:index_path) { opendata_datasets_path site, node }
  let(:new_path) { new_opendata_dataset_path site, node }

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

    describe "#index" do
      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#new" do
      before do
        category_folder = create_once(:cms_node_node, basename: "category")
        create_once(
          :opendata_node_category,
          basename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)
        area_folder = create_once(:cms_node_node, basename: "area")
        create_once(
          :opendata_node_area,
          basename: "#{area_folder.filename}/opendata_area_1",
          depth: area_folder.depth + 1)
      end

      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in "item[text]", with: "sample"
          all("input[type=checkbox][id^='item_category_ids']").each { |c| check c[:id] }
          all("input[type=checkbox][id^='item_area_ids']").each { |c| check c[:id] }
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    context "with item" do
      let(:category_folder) { create_once(:cms_node_node, basename: "category") }
      let(:category) do
        create_once(
          :opendata_node_category,
          basename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)
      end
      let(:area_folder) { create_once(:cms_node_node, basename: "area") }
      let(:area) do
        create_once(
          :opendata_node_area,
          basename: "#{area_folder.filename}/opendata_area_1",
          depth: area_folder.depth + 1)
      end
      let(:item) do
        create_once :opendata_dataset,
                    filename: "#{node.filename}/#{unique_id}.html",
                    category_ids: [ category.id ],
                    area_ids: [ area.id ]
      end
      let(:show_path) { opendata_dataset_path site, node, item }
      let(:edit_path) { edit_opendata_dataset_path site, node, item }
      let(:delete_path) { delete_opendata_dataset_path site, node, item }

      describe "#show" do
        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).not_to eq sns_login_path
        end
      end

      describe "#edit" do
        it do
          visit edit_path
          within "form#item-form" do
            fill_in "item[name]", with: "#{item.name}-modify"
            fill_in "item[text]", with: "sample-#{unique_id}"
            click_button "保存"
          end
          expect(current_path).not_to eq sns_login_path
          expect(page).not_to have_css("form#item-form")
        end
      end

      describe "#delete" do
        it do
          visit delete_path
          within "form" do
            click_button "削除"
          end
          expect(current_path).to eq index_path
        end
      end
    end
  end

  context "public side" do
    let(:category) { create_once :opendata_node_category, basename: "opendata_category1" }
    let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
    let(:item) do
      create_once :opendata_dataset,
                  filename: "#{node.filename}/#{unique_id}.html",
                  category_ids: [ category.id ],
                  area_ids: [ area.id ]
    end
    let(:public_path) { "#{item.url}" }

    it do
      # blow code can only work with Rack::Test.
      expect(Capybara.current_driver).to be :rack_test
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit public_path
        expect(current_path).to eq public_path
        # page.save_page
        expect(page).to have_css("header h1")
        expect(page).to have_css("div.point")
        expect(page).to have_css("nav.categories")
        expect(page).to have_css("div.text")
        expect(page).to have_css("div.dataset-tabs")
      end
    end
  end

  context "with disallowed category/area" do
    let(:root_group) { cms_group }
    let(:group1) { create(:cms_group, name: "#{root_group.name}/group1") }
    let(:group2) { create(:cms_group, name: "#{root_group.name}/group2") }
    let(:category_root) { create_once(:cms_node_node, basename: 'root_category', group_ids: [ group1.id, group2.id ]) }
    let(:category1) do
      create(
        :opendata_node_category,
        cur_node: category_root,
        depth: category_root.depth + 1,
        group_ids: [group1.id])
    end
    let(:category2) do
      create(
        :opendata_node_category,
        cur_node: category_root,
        depth: category_root.depth + 1,
        group_ids: [group2.id])
    end
    let(:area_root) { create_once(:cms_node_node, basename: 'root_area', group_ids: [ group1.id, group2.id ]) }
    let(:area1) do
      create(:opendata_node_area, cur_node: area_root, depth: area_root.depth + 1, group_ids: [ group1.id ])
    end
    let(:area2) do
      create(:opendata_node_area, cur_node: area_root, depth: area_root.depth + 1, group_ids: [ group2.id ])
    end
    let(:item) do
      create(
        :opendata_dataset,
        cur_node: node,
        category_ids: [ category1.id ],
        area_ids: [ area1.id ],
        group_ids: [ group1.id, group2.id ])
    end
    let(:role) do
      permissions = Cms::Role.permission_names
      permissions = permissions.select { |name| name.include?('_opendata_') }
      permissions = permissions.reject { |name| name.include?('_other_') }
      permissions += Cms::Role.permission_names.select { |name| name.include?('read_private_') }
      Cms::Role.create!(
        name: "role_#{unique_id}",
        permissions: permissions,
        site_id: site.id
      )
    end
    let(:show_path) { opendata_dataset_path(site, node, item) }
    let(:edit_path) { edit_opendata_dataset_path(site, node, item) }
    let(:delete_path) { delete_opendata_dataset_path(site, node, item) }

    before do
      group_ids = node.group_ids
      group_ids ||= []
      group_ids << group1.id
      group_ids << group2.id
      node.group_ids = group_ids
      node.save!
    end
    before { login_user(user) }

    context 'with logged in user belonged to group1' do
      let(:user) { create(:cms_test_user, group: group1, role: role, in_password: "pass") }

      it do
        visit show_path
        within 'div#addon-opendata-agents-addons-category' do
          expect(page).to have_content("#{category_root.name}/#{category1.name}")
        end
        within 'div#addon-opendata-agents-addons-area' do
          expect(page).to have_content(area1.name)
        end

        visit edit_path
        within 'div#addon-opendata-agents-addons-category dd.allowed-categories' do
          expect(page).to have_content(category1.name)
        end
        within 'div#addon-opendata-agents-addons-area dd.allowed-areas' do
          expect(page).to have_content(area1.name)
        end
        within 'div#addon-opendata-agents-addons-category' do
          expect(page).not_to have_css('dd.disallowed-categories')
        end
        within 'div#addon-opendata-agents-addons-area' do
          expect(page).not_to have_css('dd.disallowed-areas')
        end
      end
    end

    context 'with logged in user belonged to group2' do
      let(:user) { create(:cms_test_user, group: group2, role: role, in_password: "pass") }

      it do
        visit show_path
        within 'div#addon-opendata-agents-addons-category' do
          expect(page).to have_content("#{category_root.name}/#{category1.name}")
        end
        within 'div#addon-opendata-agents-addons-area' do
          expect(page).to have_content("#{area1.name}")
        end

        visit edit_path
        within 'div#addon-opendata-agents-addons-category dd.disallowed-categories' do
          expect(page).to have_content('閲覧が許可されていない分野')
          expect(page).to have_content("#{category_root.name}/#{category1.name}")
        end
        within 'div#addon-opendata-agents-addons-area dd.disallowed-areas' do
          expect(page).to have_content('閲覧が許可されていない地域')
          expect(page).to have_content("#{area1.name}")
        end
      end
    end
  end
end
