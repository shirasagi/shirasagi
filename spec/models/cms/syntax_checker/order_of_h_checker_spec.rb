require 'spec_helper'

describe Cms::SyntaxChecker::OrderOfHChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{head_htmls.join}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], [], false, 0) }

    context "with usual case" do
      let(:head_html1) { "<h2>#{unique_id}</h2>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_html3) { "<h4>#{unique_id}</h4>" }
      let(:head_html4) { "<h4>#{unique_id}</h4>" }
      let(:head_html5) { "<h3>#{unique_id}</h3>" }
      let(:head_html6) { "<h4>#{unique_id}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3, head_html4, head_html5, head_html6 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)
        expect(context.errors).to be_blank
      end
    end

    context "with h2 is skipped" do
      let(:head_html1) { "<h1>#{unique_id}</h1>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_html3) { "<h4>#{unique_id}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "h3"
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "with h3 is skipped" do
      let(:head_html1) { "<h1>#{unique_id}</h1>" }
      let(:head_html2) { "<h2>#{unique_id}</h2>" }
      let(:head_html3) { "<h4>#{unique_id}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "h4"
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "with h4 is skipped" do
      let(:head_html1) { "<h2>#{unique_id}</h2>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_html3) { "<h5>#{unique_id}</h5>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "h5"
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "when first level is 1 or 2" do
      let(:level) { rand(1..2) }
      let(:head_html1) { "<h#{level}>#{unique_id}</h#{level}>" }
      let(:head_htmls) { [ head_html1 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to be_blank
      end

      context "when first level is 3, 4, 5, or 6" do
        let(:level) { rand(3..6) }
        let(:head_html1) { "<h#{level}>#{unique_id}</h#{level}>" }
        let(:head_htmls) { [ head_html1 ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq "h#{level}"
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end
    end

    context "with multiple headers is skipped" do
      let(:head_html1) { "<h2>#{unique_id}</h2>" }
      let(:head_html2) { "<h4>#{unique_id}</h4>" }
      let(:head_html3) { "<h3>#{unique_id}</h3>" }
      let(:head_html4) { "<h5>#{unique_id}</h5>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3, head_html4 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "h4 h5"
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "header_checkがtrueのとき" do
      let(:level) { rand(3..6) }
      let(:head_html1) { "<h#{level}>#{unique_id}</h#{level}>" }
      let(:head_htmls) { [ head_html1 ] }
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], [], true, level) }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.header_check).to eq true
        expect(context.errors).to be_blank
      end
    end

    context "header_checkがfalseのとき" do
      let(:level) { rand(3..6) }
      let(:head_html1) { "<h#{level}>#{unique_id}</h#{level}>" }
      let(:head_htmls) { [ head_html1 ] }
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], [], false, level) }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.header_check).to eq false
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq "h#{level}"
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "h2,h3で数字が連続しているとき" do
      let(:head_html1) { "<h2>#{unique_id}</h2>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_htmls) { [ head_html1, head_html2 ] }
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], [], true, 2) }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.header_check).to eq true
        expect(context.errors).to be_blank
      end
    end

    context "h1,h3で数字が連続していないとき" do
      let(:head_html1) { "<h1>#{unique_id}</h1>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_htmls) { [ head_html1, head_html2 ] }
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], [], true, 1) }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.header_check).to eq true
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_order_of_h')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
        end
      end
    end
    
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{head_htmls.join}</div>" }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }
    let(:params) { nil }

    context "with no errors" do
      let(:head_html1) { "<h2>#{unique_id}</h2>" }
      let(:head_html2) { "<h3>#{unique_id}</h3>" }
      let(:head_html3) { "<h4>#{unique_id}</h4>" }
      let(:head_html4) { "<h4>#{unique_id}</h4>" }
      let(:head_html5) { "<h3>#{unique_id}</h3>" }
      let(:head_html6) { "<h4>#{unique_id}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3, head_html4, head_html5, head_html6 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include head_html1, head_html2, head_html3, head_html4, head_html5, head_html6
      end
    end
    context "with first level is skipped" do
      let(:head1) { unique_id }
      let(:head2) { unique_id }
      let(:head3) { unique_id }
      let(:head_html1) { "<h3>#{head1}</h3>" }
      let(:head_html2) { "<h3>#{head2}</h3>" }
      let(:head_html3) { "<h3>#{head3}</h3>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include "<h1>#{head1}</h1>", "<h2>#{head2}</h2>", "<h3>#{head3}</h3>"
      end
    end

    context "with h2 is skipped" do
      let(:head1) { unique_id }
      let(:head2) { unique_id }
      let(:head3) { unique_id }
      let(:head_html1) { "<h1>#{head1}</h1>" }
      let(:head_html2) { "<h3>#{head2}</h3>" }
      let(:head_html3) { "<h4>#{head3}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include "<h1>#{head1}</h1>", "<h2>#{head2}</h2>", "<h2>#{head3}</h2>"
      end
    end

    context "with h3 is skipped" do
      let(:head1) { unique_id }
      let(:head2) { unique_id }
      let(:head3) { unique_id }
      let(:head_html1) { "<h1>#{head1}</h1>" }
      let(:head_html2) { "<h2>#{head2}</h2>" }
      let(:head_html3) { "<h4>#{head3}</h4>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include "<h1>#{head1}</h1>", "<h2>#{head2}</h2>", "<h2>#{head3}</h2>"
      end
    end

    context "with h4 is skipped" do
      let(:head1) { unique_id }
      let(:head2) { unique_id }
      let(:head3) { unique_id }
      let(:head_html1) { "<h2>#{head1}</h2>" }
      let(:head_html2) { "<h3>#{head2}</h3>" }
      let(:head_html3) { "<h5>#{head3}</h5>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include "<h2>#{head1}</h2>", "<h3>#{head2}</h3>", "<h3>#{head3}</h3>"
      end
    end

    context "with h5 is skipped" do
      let(:head1) { unique_id }
      let(:head2) { unique_id }
      let(:head3) { unique_id }
      let(:head4) { unique_id }
      let(:head_html1) { "<h2>#{head1}</h2>" }
      let(:head_html2) { "<h3>#{head2}</h3>" }
      let(:head_html3) { "<h4>#{head3}</h4>" }
      let(:head_html4) { "<h6>#{head4}</h6>" }
      let(:head_htmls) { [ head_html1, head_html2, head_html3, head_html4 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include "<h2>#{head1}</h2>", "<h3>#{head2}</h3>", "<h4>#{head3}</h4>", "<h4>#{head4}</h4>"
      end
    end
  end
end
