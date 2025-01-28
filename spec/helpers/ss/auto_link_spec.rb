require 'spec_helper'

RSpec.describe SS::AutoLink, type: :helper do
  describe '#ss_auto_link' do
    before do
      controller.request.path_parameters = { site: 1 }
    end

    context "with invalid url" do
      let(:text) { "https://●●" }
      let(:html) do
        helper.ss_auto_link(text, link: :urls, sanitize: false, link_to: SS::Addon::Markdown.method(:markdown_link_to))
      end

      it do
        html_doc = Nokogiri::HTML.fragment(html)
        expect(html_doc.css("a").count).to eq 1
        html_doc.css("a").first.tap do |anchor|
          expect(anchor[:href]).to start_with("/.mypage/redirect?ref=")
          expect(anchor["data-href"]).to eq "https://"
          expect(anchor["data-controller"]).to include "ss--open-external-link-in-new-tab"
        end
      end
    end
  end
end
