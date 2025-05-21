require 'spec_helper'

describe 'cms_agents_nodes_archive', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:layout) { create_cms_layout }
  let!(:root_node) { create :article_node_page, cur_site: site }
  let!(:archive_node) { create :cms_node_archive, cur_node: root_node, layout: layout, archive_view: "yearly_list" }

  let!(:now) { Time.zone.now }
  let!(:year1) { now.advance(years: -1) }
  let!(:year2) { now }
  let!(:year3) { now.advance(years: 1) }

  let!(:item1) { create(:article_page, cur_site: site, cur_node: root_node, released: year1) }
  let!(:item2) { create(:article_page, cur_site: site, cur_node: root_node, released: year2) }
  let!(:item3) { create(:article_page, cur_site: site, cur_node: root_node, released: year3) }

  let!(:t_year) { I18n.t("datetime.prompts.year") }
  let!(:t_month) { I18n.t("datetime.prompts.month") }
  let!(:t_day) { I18n.t("datetime.prompts.day") }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context 'visit yearly' do
    let!(:title1) { "#{year1.year}#{t_year}" }
    let!(:title2) { "#{year2.year}#{t_year}" }
    let!(:title3) { "#{year3.year}#{t_year}" }

    it do
      visit archive_node.url
      within ".cms-pages" do
        within ".archive-list .years" do
          expect(page).to have_css("a", text: title1)
          expect(page).to have_css("a.current", text: title2)
          expect(page).to have_css("a", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item2.name
        end
      end

      click_on title1
      within ".cms-pages" do
        within ".archive-list .years" do
          expect(page).to have_css("a.current", text: title1)
          expect(page).to have_css("a", text: title2)
          expect(page).to have_css("a", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item1.name
        end
      end

      click_on title3
      within ".cms-pages" do
        within ".archive-list .years" do
          expect(page).to have_css("a", text: title1)
          expect(page).to have_css("a", text: title2)
          expect(page).to have_css("a.current", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item3.name
        end
      end
    end
  end

  context 'visit monthly' do
    let!(:title1) { "#{year1.year}#{t_year}#{year1.month}#{t_month}" }
    let!(:title2) { "#{year2.year}#{t_year}#{year2.month}#{t_month}" }
    let!(:title3) { "#{year3.year}#{t_year}#{year3.month}#{t_month}" }

    it do
      visit "#{archive_node.url}#{now.strftime('%Y%m')}/"
      within ".cms-pages" do
        within ".archive-list .months" do
          expect(page).to have_css("a", text: title1)
          expect(page).to have_css("a.current", text: title2)
          expect(page).to have_css("a", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item2.name
        end
      end

      click_on title1
      within ".cms-pages" do
        within ".archive-list .months" do
          expect(page).to have_css("a.current", text: title1)
          expect(page).to have_css("a", text: title2)
          expect(page).to have_css("a", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item1.name
        end
      end

      click_on title3
      within ".cms-pages" do
        within ".archive-list .months" do
          expect(page).to have_css("a", text: title1)
          expect(page).to have_css("a", text: title2)
          expect(page).to have_css("a.current", text: title3)
        end
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item3.name
        end
      end
    end
  end

  context 'visit daily' do
    let!(:title) { "#{now.year}#{t_year}#{now.month}#{t_month}#{now.day}#{t_day}" }

    it do
      visit "#{archive_node.url}#{now.strftime('%Y%m%d')}/"
      within ".cms-pages" do
        expect(page).to have_css(".event-date", text: title)
        expect(page).to have_selector("article", count: 1)
        within first("article") do
          expect(page).to have_link item2.name
        end
      end
    end
  end
end
