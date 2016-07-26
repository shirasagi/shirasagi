require 'spec_helper'

describe "opendata_ideas", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_idea, name: "opendata_idea" }
  let!(:node_search) { create_once :opendata_node_search_idea }
  let(:index_path) { opendata_ideas_path site, node }
  let(:new_path) { new_opendata_idea_path site, node }

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
        create_once(:opendata_node_area, basename: "opendata_area_1")
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
      let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
      let(:item) do
        create :opendata_idea,
               cur_site: site,
               cur_node: node,
               filename: "#{unique_id}.html",
               category_ids: [ category.id ],
               area_ids: [ area.id ]
      end
      let(:show_path) { opendata_idea_path site, node, item }
      let(:edit_path) { edit_opendata_idea_path site, node, item }
      let(:delete_path) { delete_opendata_idea_path site, node, item }

      let(:comment_text) { "管理画面コメント０１" }

      describe "#show" do
        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).not_to eq sns_login_path
        end
      end

      describe "#comment" do
        it do
          visit show_path

          click_link "コメントを管理する"

          click_link "新規作成"

          fill_in "item_text", with: comment_text
          click_button "保存"

          click_link "一覧へ戻る"

          fill_in "s_keyword", with: comment_text
          click_button "検索"

          click_link comment_text

          click_link "削除する"

          click_button "削除"

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
      create :opendata_idea,
             cur_site: site,
             cur_node: node,
             filename: "#{unique_id}.html",
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
#        expect(page).to have_css("header h1")
#        expect(page).to have_css("div.point")
#        expect(page).to have_css("nav.categories")
#        expect(page).to have_css("div.text")
#        expect(page).to have_css("div.idea-tabs")
      end
    end
  end
end
