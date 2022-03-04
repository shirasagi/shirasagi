require 'spec_helper'

describe Cms::SyntaxChecker::EmbeddedMediaChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{media_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single embedded media tag" do
      shared_examples "what embedded media tag is" do
        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq media_html
            expect(error[:msg]).to eq I18n.t('errors.messages.check_embedded_media')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_embedded_media')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when embed tag is given" do
        let(:media_html) { '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when embed with data-url tag is given" do
        let(:media_html) { '<embed type="video/webm" src="data:video/webm;base64,SGVsbG8sIFdvcmxkIQ==">' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when video tag is given" do
        let(:media_html) { '<video type="video/webm" src="/fs/1/1/1/_/video.mp4"></video>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when audio tag is given" do
        let(:media_html) { '<audio controls="" src="/fs/1/1/1/_/sound.mp3"></audio>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when iframe with media file is given" do
        let(:media_html) { '<iframe src="/fs/1/1/1/_/sound.mp3"></iframe>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when iframe with youtube is given" do
        let(:media_html) { '<iframe src="https://www.youtube.com/watch?v=D63lFSqYGT4"></iframe>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when iframe with non-media src is given" do
        let(:media_html) { '<iframe src="/docs/111.html"></iframe>' }
        let(:media_htmls) { [ media_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "when a-tag with media file is given" do
        let(:media_html) { '<a href="/fs/1/1/1/_/sound.mp3"></a>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when a-tag with youtube is given" do
        let(:media_html) { '<a href="https://www.youtube.com/watch?v=D63lFSqYGT4"></a>' }
        let(:media_htmls) { [ media_html ] }

        it_behaves_like "what embedded media tag is"
      end

      context "when a-tag with non-media src is given" do
        let(:media_html) { '<a href="/docs/111.html"></a>' }
        let(:media_htmls) { [ media_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end
    end

    context "with multiple embedded media tags" do
      let(:media_html1) { '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }
      let(:media_html2) { '<iframe src="https://www.youtube.com/watch?v=D63lFSqYGT4"></iframe>' }
      let(:media_html3) { '<a href="/fs/1/1/1/_/sound.mp3"></a>' }
      let(:media_htmls) { [ media_html1, media_html2, media_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(3).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq media_html1
          expect(error[:msg]).to eq I18n.t('errors.messages.check_embedded_media')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_embedded_media')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
