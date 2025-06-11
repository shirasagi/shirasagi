require 'spec_helper'

describe "article_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :article_part_page, filename: "node/part" }

  context "public" do
    let!(:item) { create :article_page, layout_id: layout.id, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/mobile/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_selector(".current")
    end
  end

  context "request_dir" do
    let!(:item) { create :article_page, cur_node: node }
    let(:node2) { create :article_node_page, layout_id: layout.id }
    let!(:item2) { create :article_page, cur_node: node2 }

    before do
      part.upper_html = '<div class="parts">'
      part.lower_html = '</div>'
      part.conditions = [ "\#{request_dir}" ]
      part.save!
    end

    it do
      visit "#{node.full_url}/index.html"
      expect(page).to have_css(".parts", text: item.name)
      expect(page).to have_no_css(".parts", text: item2.name)

      visit "#{node2.full_url}/index.html"
      expect(page).to have_no_css(".parts", text: item.name)
      expect(page).to have_css(".parts", text: item2.name)
    end
  end

  context "with liquid" do
    let(:part) { create :article_part_page, filename: "node/part", loop_format: 'liquid' }
    let!(:item) { create :article_page, layout_id: layout.id, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/mobile/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_selector(".current")
    end
  end

  context "with さまざまな公開予約" do
    let!(:item0) { create :article_page, cur_site: site, cur_node: node, layout: layout, state: "public" }
    let!(:item1) { create :article_page, cur_site: site, cur_node: node, layout: layout, state: "closed" }
    let!(:item2) { create :article_page, cur_site: site, cur_node: node, layout: layout, state: "public" }
    let!(:item3) { create :article_page, cur_site: site, cur_node: node, layout: layout, state: "closed" }
    let(:now) { Time.zone.now.change(sec: 0) }

    before do
      # item1: 公開開始前
      item1.release_date = now + 1.day
      item1.state = "ready"
      item1.save!

      # item2: 公開終了日が過ぎているがシステム障害により公開タスクが実行されないのでpublicのまま
      item2.set(close_date: (now - 1.day).utc)

      # item3: 公開開始日が過ぎているがシステム障害により公開タスクが実行されないのでreadyのまま
      item3.set(release_date: (now - 1.day).utc, state: "ready")

      expect(item0.state).to eq "public"
      expect(item1.state).to eq "ready"
      expect(item2.state).to eq "public"
      expect(item3.state).to eq "ready"

      ::FileUtils.rm_rf(item0.path)
      ::FileUtils.rm_rf(item1.path)
      ::FileUtils.rm_rf(item2.path)
      ::FileUtils.rm_rf(item3.path)

      part.upper_html = '<div class="parts">'
      part.lower_html = '</div>'
      part.save!
    end

    it do
      visit "#{node.full_url}/index.html"
      within ".parts" do
        expect(page).to have_css("article", count: 1)
        within ".item-#{::File.basename(item0.basename, ".*")}" do
          expect(page).to have_link(item0.name, href: item0.url)
        end
      end
    end
  end

  context "with sort_column_name" do
    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
    let!(:column) do
      create(
        :cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text'
      )
    end
    let!(:item1) { create :article_page, cur_site: site, cur_node: node, layout: layout, form: form }
    let!(:item2) { create :article_page, cur_site: site, cur_node: node, layout: layout, form: form }
    let!(:item3) { create :article_page, cur_site: site, cur_node: node, layout: layout, form: form }
    let!(:item4) { create :article_page, cur_site: site, cur_node: node, layout: layout, form: form }

    before do
      item1.column_values = [
        column.value_type.new(column: column, value: 1)
      ]
      item1.save!

      item2.column_values = [
        column.value_type.new(column: column, value: nil)
      ]
      item2.save!

      item3.column_values = [
        column.value_type.new(column: column, value: 3)
      ]
      item3.save!

      item4.column_values = [
        column.value_type.new(column: column, value: 2)
      ]
      item4.save!
    end

    context "when sort_column_direction is asc" do
      let(:part) do
        create :article_part_page, filename: "node/part", sort_column_name: column.name, sort_column_direction: 'asc'
      end

      it do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".article-pages")
        expect(page).to have_selector(".article-pages article", count: 4)
        expect(page).to have_no_selector(".article-pages .tag-article")
        expect(page).to have_no_selector(".current")

        expect(page.all(".article-pages article")[0]).to have_content(item2.name)
        expect(page.all(".article-pages article")[1]).to have_content(item1.name)
        expect(page.all(".article-pages article")[2]).to have_content(item4.name)
        expect(page.all(".article-pages article")[3]).to have_content(item3.name)
      end
    end

    context "when sort_column_direction is desc" do
      let(:part) do
        create :article_part_page, filename: "node/part", sort_column_name: column.name, sort_column_direction: 'desc'
      end

      it do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".article-pages")
        expect(page).to have_selector(".article-pages article", count: 4)
        expect(page).to have_no_selector(".article-pages .tag-article")
        expect(page).to have_no_selector(".current")

        expect(page.all(".article-pages article")[0]).to have_content(item3.name)
        expect(page.all(".article-pages article")[1]).to have_content(item4.name)
        expect(page.all(".article-pages article")[2]).to have_content(item1.name)
        expect(page.all(".article-pages article")[3]).to have_content(item2.name)
      end
    end
  end
end
