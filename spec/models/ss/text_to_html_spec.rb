require 'spec_helper'

describe SS::Addon::Markdown do
  describe ".text_to_html" do
    context "when auto_link is false and sanitize is false" do
      it do
        SS::Addon::Markdown.text_to_html(nil, auto_link: false, sanitize: false).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("", auto_link: false, sanitize: false).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("hello", auto_link: false, sanitize: false).tap do |html|
          expect(html).to eq "<p>hello</p>"
        end

        "https://www.example.jp/".tap do |url|
          SS::Addon::Markdown.text_to_html(url, auto_link: false, sanitize: false).tap do |html|
            expect(html).to eq "<p>https://www.example.jp/</p>"
          end
        end

        "<script>alert('xss');</script>".tap do |script|
          SS::Addon::Markdown.text_to_html(script, auto_link: false, sanitize: false).tap do |html|
            expect(html).to eq script
          end
        end
      end
    end

    context "when auto_link is true and sanitize is false" do
      it do
        SS::Addon::Markdown.text_to_html(nil, auto_link: true, sanitize: false).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("", auto_link: true, sanitize: false).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("hello", auto_link: true, sanitize: false).tap do |html|
          expect(html).to eq "<p>hello</p>"
        end

        "https://www.example.jp/".tap do |url|
          SS::Addon::Markdown.text_to_html(url, auto_link: true, sanitize: false).tap do |html|
            link = Rails.application.routes.url_helpers.sns_redirect_path(ref: "https://www.example.jp/")

            fragment = Nokogiri::HTML.fragment(html)
            anchors = fragment.css("a")
            expect(anchors).to have(1).items
            anchors[0].tap do |anchor|
              expect(anchor.attr("href")).to eq link
              expect(anchor.attr("data-controller")).to eq "ss--open-external-link-in-new-tab"
              expect(anchor.attr("data-href")).to eq url
              expect(anchor.text).to eq url
            end
          end
        end

        "<script>alert('xss');</script>".tap do |script|
          SS::Addon::Markdown.text_to_html(script, auto_link: true, sanitize: false).tap do |html|
            expect(html).to eq script
          end
        end
      end
    end

    context "when auto_link is false and sanitize is true" do
      it do
        SS::Addon::Markdown.text_to_html(nil, auto_link: false, sanitize: true).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("", auto_link: false, sanitize: true).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("hello", auto_link: false, sanitize: true).tap do |html|
          expect(html).to eq "<p>hello</p>"
        end

        "https://www.example.jp/".tap do |url|
          SS::Addon::Markdown.text_to_html(url, auto_link: false, sanitize: true).tap do |html|
            expect(html).to eq "<p>https://www.example.jp/</p>"
          end
        end

        "<script>alert('xss');</script>".tap do |script|
          SS::Addon::Markdown.text_to_html(script, auto_link: false, sanitize: true).tap do |html|
            expect(html).to eq "alert('xss');"
          end
        end
      end
    end

    context "when auto_link is true and sanitize is true" do
      it do
        SS::Addon::Markdown.text_to_html(nil, auto_link: true, sanitize: true).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("", auto_link: true, sanitize: true).tap do |html|
          expect(html).to be_blank
        end

        SS::Addon::Markdown.text_to_html("hello", auto_link: true, sanitize: true).tap do |html|
          expect(html).to eq "<p>hello</p>"
        end

        "https://www.example.jp/".tap do |url|
          SS::Addon::Markdown.text_to_html(url, auto_link: true, sanitize: true).tap do |html|
            link = Rails.application.routes.url_helpers.sns_redirect_path(ref: "https://www.example.jp/")

            fragment = Nokogiri::HTML.fragment(html)
            anchors = fragment.css("a")
            expect(anchors).to have(1).items
            anchors[0].tap do |anchor|
              expect(anchor.attr("href")).to eq link
              expect(anchor.attr("data-controller")).to eq "ss--open-external-link-in-new-tab"
              expect(anchor.attr("data-href")).to eq url
              expect(anchor.text).to eq url
            end
          end
        end

        "<script>alert('xss');</script>".tap do |script|
          SS::Addon::Markdown.text_to_html(script, auto_link: true, sanitize: true).tap do |html|
            expect(html).to eq "alert('xss');"
          end
        end
      end
    end
  end
end
