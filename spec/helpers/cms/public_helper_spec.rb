require 'spec_helper'

describe Cms::PublicHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }

  describe "#body_id" do
    it do
      expect(helper.body_id("/docs/index.html")).to eq "body--docs-index"
      expect(helper.body_id("/gyosei/docs/69885.html")).to eq "body--gyosei-docs-69885"
    end
  end

  describe "#body_class" do
    it do
      expect(helper.body_class("/docs/index.html")).to eq "body--docs"
      expect(helper.body_class("/gyosei/docs/69885.html")).to eq "body--gyosei body--gyosei-docs"
    end
  end

  describe "#paginate" do
    let(:limit) { 30 }
    let(:page_index) { 9 }
    let(:offset) { page_index * limit }
    let(:total_page) { 30 }
    let(:total_count) { total_page * limit + rand(1..limit - 1) }
    let(:items) do
      items = Array.new(limit) { "item-#{unique_id}" }
      Kaminari.paginate_array(items, limit: limit, offset: offset, total_count: total_count)
    end

    context "when @cur_path is given" do
      before do
        @cur_path = "/gyosei/docs/index.html"
      end

      context "without query parameters" do
        it do
          html = helper.paginate(items)
          html = Nokogiri::HTML.fragment(html)
          expect(html.css(".first a")[0]).to be_present
          expect(html.css(".first a")[0].attr("href")).to eq "/gyosei/docs"
          expect(html.css(".first a")[0].text()).to eq "«"

          expect(html.css(".prev a")[0]).to be_present
          expect(html.css(".prev a")[0].attr("href")).to eq "/gyosei/docs/index.p9.html"
          expect(html.css(".prev a")[0].text()).to eq I18n.t("views.pagination.previous")

          expect(html.css(".page")).to have(11).items
          expect(html.css(".page.current")[0].text()).to include "10"

          expect(html.css(".gap")).to have(2).items

          expect(html.css(".next a")[0]).to be_present
          expect(html.css(".next a")[0].attr("href")).to eq "/gyosei/docs/index.p11.html"
          expect(html.css(".next a")[0].text()).to eq I18n.t("views.pagination.next")

          expect(html.css(".last a")[0]).to be_present
          expect(html.css(".last a")[0].attr("href")).to eq "/gyosei/docs/index.p31.html"
          # expect(html.css(".last a")[0].text()).to eq CGI.unescapeHTML(I18n.t("views.pagination.last"))
          expect(html.css(".last a")[0].text()).to eq "»"
        end
      end

      context "with query parameters" do
        before do
          controller.request.query_string = { keyword: "test" }.to_query
        end

        it do
          html = helper.paginate(items)
          html = Nokogiri::HTML.fragment(html)
          expect(html.css(".first a")[0]).to be_present
          expect(html.css(".first a")[0].attr("href")).to eq "/gyosei/docs?keyword=test"
          expect(html.css(".first a")[0].text()).to eq "«"
        end
      end
    end

    context "when @cur_path is absent" do
      it do
        controller.params[:controller] = 'cms/public'
        controller.params[:action] = 'index'

        html = helper.paginate(items)
        html = Nokogiri::HTML.fragment(html)
        expect(html.css(".first a")[0]).to be_present
        expect(html.css(".first a")[0].attr("href")).to eq "/"
        expect(html.css(".first a")[0].text()).to eq "«"

        expect(html.css(".prev a")[0]).to be_present
        expect(html.css(".prev a")[0].attr("href")).to eq "/?page=9"
        expect(html.css(".prev a")[0].text()).to eq I18n.t("views.pagination.previous")

        expect(html.css(".page")).to have(11).items
        expect(html.css(".page.current")[0].text()).to include "10"

        expect(html.css(".gap")).to have(2).items

        expect(html.css(".next a")[0]).to be_present
        expect(html.css(".next a")[0].attr("href")).to eq "/?page=11"
        expect(html.css(".next a")[0].text()).to eq I18n.t("views.pagination.next")

        expect(html.css(".last a")[0]).to be_present
        expect(html.css(".last a")[0].attr("href")).to eq "/?page=31"
        # expect(html.css(".last a")[0].text()).to eq CGI.unescapeHTML(I18n.t("views.pagination.last"))
        expect(html.css(".last a")[0].text()).to eq "»"
      end
    end
  end
end
