require 'spec_helper'

describe "article_agents_parts_page_navi", type: :feature, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let!(:node) { create :article_node_page, cur_site: site, sort: "released -1" }
  let!(:part) { create :article_part_page_navi, cur_site: site, cur_node: node }

  context "when the part is integrated into cms/layout" do
    let!(:layout) { create_cms_layout part, cur_site: site }
    let!(:page1) do
      released = now - 5.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, state: "public",
          released_type: "fixed", released: released)
      end
    end
    let!(:page2) do
      released = now - 4.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, state: "public",
          released_type: "fixed", released: released)
      end
    end
    let!(:page3) do
      released = now - 3.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, state: "public",
          released_type: "fixed", released: released)
      end
    end
    let!(:page4) do
      released = now - 2.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, state: "public",
          released_type: "fixed", released: released)
      end
    end

    before do
      FileUtils.rm_rf page1.path
      FileUtils.rm_rf page2.path
      FileUtils.rm_rf page3.path
      FileUtils.rm_rf page4.path
    end

    it do
      visit page1.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".prev", text: I18n.t("article.page_navi.prev"))
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_no_css(".next")
      end

      visit page2.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".prev", text: I18n.t("article.page_navi.prev"))
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_css(".next", text: I18n.t("article.page_navi.next"))
      end

      visit page4.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_css(".next", text: I18n.t("article.page_navi.next"))
        expect(page).to have_no_css(".prev", text: I18n.t("article.page_navi.prev"))
      end
    end
  end

  context "when the part is integrated into cms/form" do
    let!(:layout) { create_cms_layout cur_site: site }
    let!(:form) do
      html = <<~HTML
        {{ parts["#{part.filename.sub(".part.html", "")}"].html }}
      HTML
      create :cms_form, cur_site: site, state: 'public', sub_type: 'static', html: html
    end
    let!(:column) do
      create(
        :cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 10, input_type: 'text'
      )
    end

    let!(:page1) do
      released = now - 5.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: "public",
          column_values: [ column.value_type.new(column: column, name: column.name, value: "text-#{unique_id}") ],
          released_type: "fixed", released: released)
      end
    end
    let!(:page2) do
      released = now - 4.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: "public",
          column_values: [ column.value_type.new(column: column, name: column.name, value: "text-#{unique_id}") ],
          released_type: "fixed", released: released)
      end
    end
    let!(:page3) do
      released = now - 3.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: "public",
          column_values: [ column.value_type.new(column: column, name: column.name, value: "text-#{unique_id}") ],
          released_type: "fixed", released: released)
      end
    end
    let!(:page4) do
      released = now - 2.hours
      Timecop.freeze(released) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: "public",
          column_values: [ column.value_type.new(column: column, name: column.name, value: "text-#{unique_id}") ],
          released_type: "fixed", released: released)
      end
    end

    before do
      FileUtils.rm_rf page1.path
      FileUtils.rm_rf page2.path
      FileUtils.rm_rf page3.path
      FileUtils.rm_rf page4.path
    end

    it do
      visit page1.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".prev", text: I18n.t("article.page_navi.prev"))
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_no_css(".next")
      end

      visit page2.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".prev", text: I18n.t("article.page_navi.prev"))
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_css(".next", text: I18n.t("article.page_navi.next"))
      end

      visit page4.full_url
      within ".page-navi-control" do
        expect(page).to have_css(".return", text: I18n.t("article.page_navi.back_to_index"))
        expect(page).to have_css(".next", text: I18n.t("article.page_navi.next"))
        expect(page).to have_no_css(".prev", text: I18n.t("article.page_navi.prev"))
      end
    end
  end
end
