require 'spec_helper'

describe Cms::SyntaxChecker::DateFormatChecker, type: :model, dbscope: :example do
  describe "#check" do
    context "with single date" do
      let(:id) { unique_id }
      let(:idx) { rand(10..20) }
      let(:raw_html) { "<div><p>#{date_str}</p></div>" }
      let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
      let(:content) do
        { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
      end
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

      shared_examples "what #check should act" do
        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq date_str
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_date_format')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_date_format')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with date separated with slash" do
        let(:date_str) { "2021/#{rand(1..12)}/#{rand(1..28)}" }

        it_behaves_like "what #check should act"
      end

      context "with date separated with hyphen" do
        let(:date_str) { "2021-#{rand(1..12)}-#{rand(1..28)}" }

        it_behaves_like "what #check should act"
      end

      context "with date separated with period" do
        let(:date_str) { "2021.#{rand(1..12)}.#{rand(1..28)}" }

        it_behaves_like "what #check should act"
      end

      context "with non-date" do
        context "with date separated with colon" do
          let(:date_str) { "2021:#{rand(1..12)}:#{rand(1..28)}" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to have(0).items
          end
        end

        context "when date is invalid" do
          let(:date_str) { "2021/#{rand(1..12)}/#{rand(32..99)}" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to have(0).items
          end
        end
      end
    end

    context "with multiple dates" do
      let(:id) { unique_id }
      let(:idx) { rand(10..20) }
      let(:raw_html) { "<div><p>#{date_str1}</p><p>#{date_str2}</p></div>" }
      let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
      let(:content) do
        { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
      end
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

      shared_examples "what #check should act" do
        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(2).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq date_str1
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_date_format')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_date_format')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
          context.errors.second.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq date_str2
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_date_format')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_date_format')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with date separated with slash" do
        let(:date_str1) { "2021/#{rand(1..12)}/#{rand(1..28)}" }
        let(:date_str2) { "2021/#{rand(1..12)}/#{rand(1..28)}" }

        it_behaves_like "what #check should act"
      end
    end
  end

  describe "#correct" do
    context "with single date" do
      let(:raw_html) { "<div><p>#{date_str}</p></div>" }
      let(:content) do
        { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
      end
      let(:params) { nil }
      let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }

      shared_examples "what #correct should act" do
        let(:date) { date_str.in_time_zone.to_date }

        it do
          described_class.new.correct(context)
          expect(context.result).to eq "<p>#{I18n.l(date, format: :long)}</p>"
        end
      end

      context "with date separated with slash" do
        let(:date_str) { "2021/#{rand(1..12)}/#{rand(1..28)}" }

        it_behaves_like "what #correct should act"
      end

      context "with date separated with hyphen" do
        let(:date_str) { "2021-#{rand(1..12)}-#{rand(1..28)}" }

        it_behaves_like "what #correct should act"
      end

      context "with date separated with period" do
        let(:date_str) { "2021.#{rand(1..12)}.#{rand(1..28)}" }

        it_behaves_like "what #correct should act"
      end

      context "with non-date" do
        context "with date separated with colon" do
          let(:date_str) { "2021:#{rand(1..12)}:#{rand(1..28)}" }

          it do
            described_class.new.correct(context)
            expect(context.result).to eq "<p>#{date_str}</p>"
          end
        end

        context "when date is invalid" do
          let(:date_str) { "2021/#{rand(1..12)}/#{rand(32..99)}" }

          it do
            described_class.new.correct(context)
            expect(context.result).to eq "<p>#{date_str}</p>"
          end
        end
      end
    end

    context "with multiple date" do
      let(:raw_html) { "<div><p>#{date_str1}</p><p>#{date_str2}</p></div>" }
      let(:content) do
        { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
      end
      let(:params) { nil }
      let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }

      context "with date separated with slash" do
        let(:date_str1) { "2021/#{rand(1..12)}/#{rand(1..28)}" }
        let(:date_str2) { "2021/#{rand(1..12)}/#{rand(1..28)}" }
        let(:date1) { date_str1.in_time_zone.to_date }
        let(:date2) { date_str2.in_time_zone.to_date }

        it do
          described_class.new.correct(context)
          expect(context.result).to eq "<p>#{I18n.l(date1, format: :long)}</p><p>#{I18n.l(date2, format: :long)}</p>"
        end
      end
    end
  end
end
