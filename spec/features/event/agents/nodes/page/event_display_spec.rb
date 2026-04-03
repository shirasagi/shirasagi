require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:upper_html) { '<div class="upper_html">upper_html</div>' }
  let!(:lower_html) { '<div class="lower_html">upper_html</div>' }
  let!(:cate1) { create :category_node_page }
  let!(:cate2) { create :category_node_page }
  let!(:node) do
    create :event_node_page, layout_id: layout.id, filename: "node", event_display: event_display,
      event_display_tabs: [event_display], st_category_ids: [cate1.id, cate2.id],
      upper_html: upper_html, lower_html: lower_html,
      table_day_loop_liquid: table_day_loop_liquid, list_day_loop_liquid: list_day_loop_liquid
  end
  let!(:today) { Time.zone.today }
  let!(:event_recur1) do
    { kind: "date", start_at: today, frequency: "daily", until_on: today }
  end
  let!(:event_recur2) do
    { kind: "date", start_at: today - 1.day, frequency: "daily", until_on: today + 1.day }
  end
  let!(:item1) { create :event_page, cur_node: node, event_recurrences: [event_recur1], category_ids: [cate1.id] }
  let!(:item2) { create :event_page, cur_node: node, event_recurrences: [event_recur2], category_ids: [cate2.id] }

  before do
    # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
  end

  context "table" do
    let(:event_display) { 'table' }

    context "default liquid" do
      let!(:table_day_loop_liquid) { nil }
      let!(:list_day_loop_liquid) { nil }

      it "index" do
        visit node.full_url
        expect(page).to have_css(".upper_html")
        expect(page).to have_css(".lower_html")
        within ".event-pages-filter" do
          expect(page).to have_link I18n.t("event.filter_all")
          expect(page).to have_link cate1.name
          expect(page).to have_link cate2.name
        end
        within "#event-table" do
          within "td.today" do
            within ".daily" do
              expect(page).to have_link today.day
            end
            within ".page.single-day" do
              within ".#{cate1.filename}" do
                expect(page).to have_link cate1.name
              end
              within ".event" do
                expect(page).to have_link item1.event_name
              end
            end
            within ".page.multiple-days" do
              within ".#{cate2.filename}" do
                expect(page).to have_link cate2.name
              end
              within ".event" do
                expect(page).to have_link item2.event_name
              end
            end
          end
        end
      end
    end

    context "custom liquid" do
      let!(:table_day_loop_liquid) do
        '<div class="day{{ day }}">{{ date | ss_date: "iso" }}</div>'
      end
      let!(:list_day_loop_liquid) { nil }

      it "index" do
        visit node.full_url
        expect(page).to have_css(".upper_html")
        expect(page).to have_css(".lower_html")
        within ".event-pages-filter" do
          expect(page).to have_link I18n.t("event.filter_all")
          expect(page).to have_link cate1.name
          expect(page).to have_link cate2.name
        end
        within "#event-table" do
          within "td.today" do
            expect(page).to have_css(".day#{today.day}", text: I18n.l(today, format: :iso))
          end
        end
      end
    end
  end

  context "list" do
    let(:event_display) { 'list' }
    let(:date_label) do
      "#{today.month}#{I18n.t("datetime.prompts.month")}#{today.day}#{I18n.t("datetime.prompts.day")}"
    end

    context "default liquid" do
      let!(:table_day_loop_liquid) { nil }
      let!(:list_day_loop_liquid) { nil }

      it "index" do
        visit node.full_url
        expect(page).to have_css(".upper_html")
        expect(page).to have_css(".lower_html")
        within ".event-pages-filter" do
          expect(page).to have_link I18n.t("event.filter_all")
          expect(page).to have_link cate1.name
          expect(page).to have_link cate2.name
        end

        within "#event-list" do
          within "dl.today" do
            within "time" do
              expect(page).to have_link date_label
            end
            within ".page.single-day" do
              within ".#{cate1.filename}" do
                expect(page).to have_link cate1.name
              end
              within "h2" do
                expect(page).to have_link item1.event_name
              end
            end
            within ".page.multiple-days" do
              within ".#{cate2.filename}" do
                expect(page).to have_link cate2.name
              end
              within "h2" do
                expect(page).to have_link item2.event_name
              end
            end
          end
        end
      end
    end

    context "custom liquid" do
      let!(:table_day_loop_liquid) { nil }
      let!(:list_day_loop_liquid) do
        '<div class="day{{ day }}">{{ date | ss_date: "iso" }}</div>'
      end

      it "index" do
        visit node.full_url
        expect(page).to have_css(".upper_html")
        expect(page).to have_css(".lower_html")
        within ".event-pages-filter" do
          expect(page).to have_link I18n.t("event.filter_all")
          expect(page).to have_link cate1.name
          expect(page).to have_link cate2.name
        end

        within "#event-list" do
          expect(page).to have_css(".day#{today.day}", text: I18n.l(today, format: :iso))
        end
      end
    end
  end

  context "map" do
    let(:event_display) { 'map' }
    let!(:table_day_loop_liquid) { nil }
    let!(:list_day_loop_liquid) { nil }

    it "index" do
      visit node.full_url
      expect(page).to have_css(".upper_html")
      expect(page).to have_css(".lower_html")
      expect(page).to have_css("#event-map")
    end
  end
end
