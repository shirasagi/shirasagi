require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create(:event_node_page, layout_id: layout.id, st_category_ids: [cate1.id, cate2.id],
      event_display: event_display, event_display_tabs: [event_display])
  end
  let!(:cate1) { create :category_node_page, order: 20 }
  let!(:cate2) { create :category_node_page, order: 10 }

  let!(:today) { Time.zone.today }
  let!(:event_recur1) do
    { kind: "date", start_at: today, frequency: "daily", until_on: today }
  end
  let!(:event_recur2) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 12),
      end_at: today.in_time_zone.change(hour: 13),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:event_recur3) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 14),
      end_at: today.in_time_zone.change(hour: 15),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:item1) do
    create(:event_page, cur_node: node, event_recurrences: [event_recur1], category_ids: [cate1.id, cate2.id])
  end
  let!(:item2) { create :event_page, cur_node: node, event_recurrences: [event_recur2] }
  let!(:item3) { create :event_page, cur_node: node, event_recurrences: [event_recur3] }

  context "table" do
    let(:event_display) { 'table' }
    let(:index_url) { node.full_url }

    context "default liquid" do
      it "#index_monthly_table" do
        visit index_url
        within "td.today" do
          expect(page).to have_selector("div.page", count: 3)
          within all("div.page")[0] do
            # name
            expect(page).to have_link(item1.event_name)
            expect(page).to have_no_css(".datetime")
            # category
            expect(page).to have_selector("div.data", count: 1)
            expect(page).to have_link(cate2.name)
            # datetime
            expect(page).to have_no_css(".datetime")
          end
          within all("div.page")[1] do
            # name
            expect(page).to have_link(item2.event_name)
            # category
            expect(page).to have_no_selector("div.data")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur2[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur2[:end_at], format: :h_mm))
            end
          end
          within all("div.page")[2] do
            # name
            expect(page).to have_link(item3.event_name)
            # category
            expect(page).to have_no_selector("div.data")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur3[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur3[:end_at], format: :h_mm))
            end
          end
        end
      end
    end

    context "with custom liquid" do
      let(:table_day_loop_liquid) do
        <<~HTML
          <ul class="custom-liquid {% if today? %}today{% endif %}">
            {% for event in events %}
              <li data-id="{{ event.page.id }}">{{ event.name }}</li>
            {% endfor %}
          </ul>
        HTML
      end

      before do
        node.table_day_loop_liquid = table_day_loop_liquid
        node.update!
      end

      it "#index_monthly_table" do
        visit index_url
        within "ul.custom-liquid.today" do
          expect(page).to have_selector("li", count: 3)
          within all("li")[0] do
            expect(page).to have_text(item1.event_name)
          end
          within all("li")[1] do
            expect(page).to have_text(item2.event_name)
          end
          within all("li")[2] do
            expect(page).to have_text(item3.event_name)
          end
        end
      end
    end
  end

  context "list" do
    let(:event_display) { 'list' }
    let(:index_url) { node.full_url }

    context "default liquid" do
      it "#index_monthly_list" do
        visit index_url
        within "dl.today" do
          expect(page).to have_selector("dd.page", count: 3)
          within all("dd.page")[0] do
            # name
            expect(page).to have_link(item1.event_name)
            # category
            expect(page).to have_selector("div.data", count: 1)
            expect(page).to have_link(cate2.name)
            # datetime
            expect(page).to have_no_css(".datetime")
          end
          within all("dd.page")[1] do
            # name
            expect(page).to have_link(item2.event_name)
            # category
            expect(page).to have_no_selector("div.data")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur2[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur2[:end_at], format: :h_mm))
            end
          end
          within all("dd.page")[2] do
            # name
            expect(page).to have_link(item3.event_name)
            # category
            expect(page).to have_no_selector("div.data")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur3[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur3[:end_at], format: :h_mm))
            end
          end
        end
      end
    end

    context "with custom liquid" do
      let(:list_day_loop_liquid) do
        <<~HTML
          <ul class="custom-liquid {% if today? %}today{% endif %}">
            {% for event in events %}
              <li data-id="{{ event.page.id }}">{{ event.name }}</li>
            {% endfor %}
          </ul>
        HTML
      end

      before do
        node.list_day_loop_liquid = list_day_loop_liquid
        node.update!
      end

      it "#index_monthly_list" do
        visit index_url
        within "ul.custom-liquid.today" do
          expect(page).to have_selector("li", count: 3)
          within all("li")[0] do
            expect(page).to have_text(item1.event_name)
          end
          within all("li")[1] do
            expect(page).to have_text(item2.event_name)
          end
          within all("li")[2] do
            expect(page).to have_text(item3.event_name)
          end
        end
      end
    end
  end

  context "daily" do
    let(:event_display) { 'list' }
    let(:index_url) { "#{node.full_url}#{today.strftime('%Y%m%d')}/" }

    context "with default liquid" do
      it "#index_daily" do
        visit index_url
        within "#event-list" do
          expect(page).to have_selector("div.page", count: 3)
          within all("div.page")[0] do
            # name
            expect(page).to have_link(item1.event_name)
            # category
            within "nav.categories" do
              expect(page).to have_selector("li", count: 2)
              within all("li")[0] do
                expect(page).to have_link(cate2.name)
              end
              within all("li")[1] do
                expect(page).to have_link(cate1.name)
              end
            end
            # datetime
            expect(page).to have_no_css(".datetime")
          end
          within all("div.page")[1] do
            # name
            expect(page).to have_link(item2.event_name)
            # category
            expect(page).to have_no_css("nav.categories")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur2[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur2[:end_at], format: :h_mm))
            end
          end
          within all("div.page")[2] do
            # name
            expect(page).to have_link(item3.event_name)
            # category
            expect(page).to have_no_css("nav.categories")
            # datetime
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur3[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur3[:end_at], format: :h_mm))
            end
          end
        end
      end
    end

    context "with custom liquid" do
      let(:daily_list_loop_liquid) do
        <<~HTML
          <ul class="custom-liquid {% if today? %}today{% endif %}">
            {% for event in events %}
              <li data-id="{{ event.page.id }}">{{ event.name }}</li>
            {% endfor %}
          </ul>
        HTML
      end

      before do
        node.daily_list_loop_liquid = daily_list_loop_liquid
        node.update!
      end

      it "#index_daily" do
        visit index_url
        within "ul.custom-liquid.today" do
          expect(page).to have_selector("li", count: 3)
          within all("li")[0] do
            expect(page).to have_text(item1.event_name)
          end
          within all("li")[1] do
            expect(page).to have_text(item2.event_name)
          end
          within all("li")[2] do
            expect(page).to have_text(item3.event_name)
          end
        end
      end
    end
  end
end
