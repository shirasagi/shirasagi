require 'spec_helper'

describe Cms::MobileSizeCheckerComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "when html is given" do
    context "when html is over the limit" do
      let(:html) { "<p>あいうえおカキクケコ</p>" * 30 }

      before do
        site.mobile_size = 1_024
        site.save!
      end

      it do
        checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
        component = described_class.new(cur_site: site, cur_user: user, checker: checker)
        fragment = render_inline component
        fragment.css("#errorMobileChecker").tap do |error_elements|
          expect(error_elements).to have(1).items
          error_elements[0].css("h2").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t("cms.mobile_size_check"))
          end
          error_elements[0].css(".errorExplanationBody").tap do |elements|
            expect(elements).to have(1).items
            messages = I18n.t(
              "errors.messages.mobile_size_check_failed_to_size",
              mobile_size: site.mobile_size.to_fs(:human_size), size: html.bytesize.to_fs(:human_size))
            expect(elements[0].text.strip).to include(messages)
          end
        end
      end
    end

    context "when html is under the limit" do
      let(:html) { "<p>あいうえおカキクケコ</p>" }

      it do
        checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
        component = described_class.new(cur_site: site, cur_user: user, checker: checker)
        fragment = render_inline component
        fragment.css("#errorMobileChecker").tap do |error_elements|
          expect(error_elements).to have(1).items
          error_elements[0].css("h2").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t("cms.mobile_size_check"))
          end
          error_elements[0].css(".errorExplanationBody").tap do |elements|
            expect(elements).to have(1).items
            expect(elements[0].text.strip).to include(I18n.t('errors.messages.mobile_size_check_size'))
          end
        end
      end
    end
  end

  context "when attachment" do
    let(:file1) do
      content_path = "#{Rails.root}/spec/fixtures/ss/logo.png"
      tmp_ss_file(Cms::TempFile, site: site, user: cms_user, contents: content_path)
    end
    let(:file2) do
      content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      tmp_ss_file(Cms::TempFile, site: site, user: cms_user, contents: content_path)
    end
    let(:html) do
      <<~HTML
        <img src=\"/fs/#{file1.id}/_/logo.png\">
        <img src=\"/fs/#{file2.id}/_/keyvisual.jpg\">
      HTML
    end

    before do
      site.mobile_state = "enabled"
      site.mobile_size = 6 * 1_024
      site.save!
      site.reload
    end

    it do
      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
      component = described_class.new(cur_site: site, cur_user: user, checker: checker)
      fragment = render_inline component
      fragment.css("#errorMobileChecker").tap do |error_elements|
        expect(error_elements).to have(1).items
        error_elements[0].css("h2").tap do |elements|
          expect(elements).to have(1).items
          expect(elements[0].text.strip).to include(I18n.t("cms.mobile_size_check"))
        end
        error_elements[0].css(".errorExplanationBody").tap do |elements|
          expect(elements).to have(1).items

          message1 = I18n.t(
            "errors.messages.too_bigfile",
            filename: file1.name, filesize: file1.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
          message2 = I18n.t(
            "errors.messages.too_bigfile",
            filename: file2.name, filesize: file2.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
          message3 = I18n.t(
            "errors.messages.too_bigsize",
            total: (file1.thumb.size + file2.thumb.size).to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
          expect(elements[0].text.strip).to include(message1, message2, message3)
        end
      end
    end
  end
end
