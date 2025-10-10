require 'spec_helper'

describe Cms::ContentLinkCheckerComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout }

  describe ".render" do
    context "html with no links" do
      let(:html) do
        <<~HTML
          <p>hello</p>
        HTML
      end
      let!(:article) do
        create :article_page, cur_node: node, layout: layout, html: html, state: "public"
      end

      it do
        checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)
        component = described_class.new(cur_site: site, cur_user: user, checker: checker)
        fragment = render_inline component
        fragment.css("#errorLinkChecker").tap do |error_elements|
          expect(error_elements).to have(1).items
          error_elements[0].css("h2").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t("cms.link_check"))
          end
          error_elements[0].css(".errorExplanationBody").tap do |elements|
            expect(elements).to have(1).items
            messages = I18n.t("errors.template.no_links")
            expect(elements[0].text.strip).to include(messages)
          end
        end
      end
    end

    context "html with several successes and failures" do
      let(:ss_file1) { create :ss_file, site: site, user: user }
      let(:ss_file2) { create :ss_file, site: site, user: user }

      let(:success_anchor1) { unique_id }
      let(:failed_anchor1) { unique_id }

      let(:success_url1) { ss_file1.url }
      let(:success_url2) { Addressable::URI.join(site.full_url, ss_file2.url).to_s }
      let(:success_url3) { "https://success.example.jp" }
      let(:success_url4) { "https://success.example.jp/?キー=値" }

      let(:failed_url1) { "/fs/1/_/failed.txt" }
      let(:failed_url2) { Addressable::URI.join(site.full_url, "/fs/2/_/2.pdf").to_s }
      let(:failed_url3) { "https://failed.example.jp" }

      let(:invalid_url1) { "https://invalid.example.jp /" }

      before do
        success_return = { body: "", status: 200, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
        Addressable::URI.join(site.full_url, success_url1).to_s.tap do |u|
          stub_request(:get, /^#{::Regexp.escape(u)}/).to_return(success_return)
        end
        stub_request(:get, /^#{::Regexp.escape(success_url2)}/).to_return(success_return)
        stub_request(:get, /^#{::Regexp.escape(success_url3)}/).to_return(success_return)
        # stub_request(:get, /^#{::Regexp.escape(success_url4)}/).to_return(success_return)
        failed_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
        Addressable::URI.join(site.full_url, failed_url1).to_s.tap do |u|
          stub_request(:get, u).to_return(failed_return)
        end
        stub_request(:get, failed_url2).to_return(failed_return)
        stub_request(:get, failed_url3).to_return(failed_return)
      end

      let(:html) do
        <<~HTML.freeze
          <a href=\"##{success_anchor1}\">#{success_anchor1}</a>
          <a href=\"##{failed_anchor1}\">#{failed_anchor1}</a>

          <a class=\"icon-png\" href=\"#{success_url1}\">#{success_url1}</a>
          <a href=\"#{success_url2}\">#{success_url2}</a>
          <a id=\"#{success_anchor1}\" href=\"#{success_url3}\">#{success_url3}</a>
          <a href=\"#{success_url4}\">#{success_url4}</a>

          <a class=\"icon-png\" href=\"#{failed_url1}\">#{failed_url1}</a>
          <a href=\"#{failed_url2}\">#{failed_url2}</a>
          <a href=\"#{failed_url3}\">#{failed_url3}</a>

          <a href=\"#{invalid_url1}\">#{invalid_url1}</a>
        HTML
      end
      let!(:article) do
        create :article_page, cur_node: node, layout: layout, html: html, file_ids: [ss_file1.id, ss_file2.id], state: "public"
      end

      it do
        checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)
        component = described_class.new(cur_site: site, cur_user: user, checker: checker)
        fragment = render_inline component
        fragment.css("#errorLinkChecker").tap do |error_elements|
          expect(error_elements).to have(1).items
          error_elements[0].css("h2").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t("cms.link_check"))
          end
          error_elements[0].css(".errorExplanationBody").tap do |elements|
            expect(elements).to have(1).items

            elements[0].css("[data-url='##{success_anchor1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".success").text.strip).to eq I18n.t("errors.messages.link_check_success")
              expect(results.css(".url").text.strip).to eq "##{success_anchor1}"
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='##{failed_anchor1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".failure").text.strip).to eq I18n.t("errors.messages.link_check_failure")
              expect(results.css(".url").text.strip).to eq "##{failed_anchor1}"
              expect(results.css(".message").text.strip).to eq I18n.t("errors.template.no_links")
            end

            elements[0].css("[data-url='#{success_url1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".success").text.strip).to eq I18n.t("errors.messages.link_check_success")
              expect(results.css(".url").text.strip).to eq success_url1
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='#{success_url2}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".success").text.strip).to eq I18n.t("errors.messages.link_check_success")
              expect(results.css(".url").text.strip).to eq success_url2
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='#{success_url3}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".success").text.strip).to eq I18n.t("errors.messages.link_check_success")
              expect(results.css(".url").text.strip).to eq success_url3
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='#{success_url4}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".success").text.strip).to eq I18n.t("errors.messages.link_check_success")
              expect(results.css(".url").text.strip).to eq success_url4
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='#{failed_url1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".failure").text.strip).to eq I18n.t("errors.messages.link_check_failure")
              expect(results.css(".url").text.strip).to eq failed_url1
              expect(results.css(".message").text.strip).to eq I18n.t("errors.messages.link_check_failed_not_found")
            end

            elements[0].css("[data-url='#{failed_url2}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".failure").text.strip).to eq I18n.t("errors.messages.link_check_failure")
              expect(results.css(".url").text.strip).to eq failed_url2
              expect(results.css(".message").text.strip).to eq I18n.t("errors.messages.link_check_failed_not_found")
            end

            elements[0].css("[data-url='#{failed_url3}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".failure").text.strip).to eq I18n.t("errors.messages.link_check_failure")
              expect(results.css(".url").text.strip).to eq failed_url3
              expect(results.css(".message").text.strip).to eq I18n.t("errors.messages.link_check_failed_not_found")
            end

            elements[0].css("[data-url='#{invalid_url1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".failure").text.strip).to eq I18n.t("errors.messages.link_check_failure")
              expect(results.css(".url").text.strip).to eq invalid_url1
              expect(results.css(".message").text.strip).to eq I18n.t("errors.messages.link_check_failed_invalid_link")
            end
          end
        end
      end
    end

    context "with 'nofollow'" do
      let(:url1) { unique_url }
      let(:url2) { unique_url }
      let(:html) do
        <<~HTML.freeze
          <!-- rel は複数の値を持つ場合がある -->
          <a href="#{url1}" rel="noreferrer nofollow" data-ss-rel="">#{url1}</a>
          <!-- rel と data-ss-rel は同時に指定される場合がある -->
          <a href="#{url2}" rel="noreferrer" data-ss-rel="nofollow">#{url2}</a>
        HTML
      end
      let!(:article) { create :article_page, cur_node: node, layout: layout, html: html, state: "public" }

      before do
        WebMock.disable_net_connect!

        failed_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
        stub_request(:get, url1).to_return(failed_return)
        stub_request(:get, url2).to_return(failed_return)
      end

      after do
        WebMock.reset!
        WebMock.allow_net_connect!
      end

      it do
        checker = Cms::ContentLinkChecker.check(cur_site: site, cur_user: user, page: article, html: html)
        component = described_class.new(cur_site: site, cur_user: user, checker: checker)
        fragment = render_inline component
        fragment.css("#errorLinkChecker").tap do |error_elements|
          expect(error_elements).to have(1).items
          error_elements[0].css("h2").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t("cms.link_check"))
          end
          error_elements[0].css(".errorExplanationBody").tap do |elements|
            expect(elements).to have(1).items

            elements[0].css("[data-url='#{url1}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".nofollow").text.strip).to eq "[nofollow]"
              expect(results.css(".url").text.strip).to eq url1
              expect(results.css(".message")).to be_blank
            end

            elements[0].css("[data-url='#{url2}']").tap do |results|
              expect(results).to have(1).items
              expect(results.css(".nofollow").text.strip).to eq "[nofollow]"
              expect(results.css(".url").text.strip).to eq url2
              expect(results.css(".message").text.strip).to be_blank
            end
          end
        end
      end
    end
  end
end
