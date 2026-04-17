require 'spec_helper'

describe Cms::HistoryListHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }
  let(:page) { create(:article_page, cur_site: site) }
  let(:part) { create(:cms_part_history_list, cur_site: site) }

  before do
    @cur_site = site
    @cur_part = part
    @item = page
    @cur_date = Time.zone.now
    @cur_path = page.url
    allow(helper).to receive(:controller).and_return(double("Controller", preview_path?: false))
  end

  describe "#render_item_list" do
    context "when loop_format is shirasagi" do
      before do
        part.loop_format = "shirasagi"
        part.save!
      end

      it "renders with shirasagi format" do
        result = helper.render_item_list
        expect(result).to be_present
      end
    end

    context "when loop_format is liquid" do
      before do
        part.loop_format = "liquid"
        part.save!
      end

      context "with valid loop_setting.html" do
        let!(:loop_setting) do
          create(:cms_loop_setting,
            site: site,
            html_format: "liquid",
            state: "public",
            html: "{% for item in items %}<li>{{ item.name }}</li>{% endfor %}")
        end

        before do
          part.loop_setting_id = loop_setting.id
          part.save!
        end

        it "uses loop_setting.html" do
          result = helper.render_item_list
          expect(result).to include("<li>")
          expect(result).to include(page.name)
        end
      end

      context "when loop_setting.html is blank" do
        let!(:loop_setting) do
          create(:cms_loop_setting,
            site: site,
            html_format: "liquid",
            state: "public",
            html: "")
        end

        before do
          part.loop_setting_id = loop_setting.id
          part.save!
        end

        it "falls back to loop_liquid or default_loop_liquid" do
          result = helper.render_item_list
          expect(result).to include("history")
          # Liquidテンプレートがレンダリングされていることを確認（実際のHTMLが生成されている）
          expect(result).to include("<li")
          expect(result).to include(page.name)
        end
      end

      context "when loop_setting.html is nil" do
        let!(:loop_setting) do
          create(:cms_loop_setting,
            site: site,
            html_format: "liquid",
            state: "public",
            html: nil)
        end

        before do
          part.loop_setting_id = loop_setting.id
          part.save!
        end

        it "falls back to loop_liquid or default_loop_liquid" do
          result = helper.render_item_list
          expect(result).to include("history")
          # Liquidテンプレートがレンダリングされていることを確認（実際のHTMLが生成されている）
          expect(result).to include("<li")
          expect(result).to include(page.name)
        end
      end

      context "when loop_setting does not respond to html_format_liquid?" do
        let(:mock_loop_setting) do
          double("MockLoopSetting", present?: true, html: "test html")
        end

        before do
          allow(part).to receive(:loop_setting).and_return(mock_loop_setting)
        end

        it "safely handles missing method and falls back" do
          expect { helper.render_item_list }.not_to raise_error
          result = helper.render_item_list
          expect(result).to be_present
        end
      end

      context "with loop_liquid present" do
        before do
          part.loop_liquid = "{% for item in items %}<div class='custom'>{{ item.name }}</div>{% endfor %}"
          part.save!
        end

        it "uses loop_liquid" do
          result = helper.render_item_list
          expect(result).to include("<div class='custom'>")
          expect(result).to include(page.name)
        end
      end

      context "without loop_setting and loop_liquid" do
        it "uses default_loop_liquid" do
          result = helper.render_item_list
          expect(result).to include("history")
          # Liquidテンプレートがレンダリングされていることを確認（実際のHTMLが生成されている）
          expect(result).to include("<li")
          expect(result).to include(page.url)
          expect(result).to include(page.name)
        end
      end
    end

    context "when @item is nil" do
      before do
        @item = nil
      end

      it "returns nil" do
        expect(helper.render_item_list).to be_nil
      end
    end
  end
end
