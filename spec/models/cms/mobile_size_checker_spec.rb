require 'spec_helper'

describe Cms::MobileSizeChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe ".check" do
    context "check_mobile_html_size" do
      it "on click check_size_button html_size too big" do
        site.mobile_size = 1_024
        site.save!

        html = "<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>" * 10
        checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)

        message = I18n.t(
          "errors.messages.mobile_size_check_failed_to_size",
          mobile_size: site.mobile_size.to_fs(:human_size), size: html.bytesize.to_fs(:human_size))
        checker.errors[:base].tap do |errors|
          expect(errors).to have(1).items
          expect(errors[0]).to eq message
        end
      end

      it "on click check_size_button html_size ok" do
        html = "<p>あいうえおカキクケコ</p>"
        checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
        expect(checker.errors[:base]).to be_blank
      end
    end
  end

  context "check_file_size" do
    let(:file) { create(:ss_file, filename: "logo.png") }
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }

    it "mobile_size 1" do
      site.mobile_state = "enabled"
      site.mobile_size = 1_024
      site.save!

      html = "<img src=\"/fs/#{file.id}/_/logo.png\">"
      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)

      message1 = I18n.t(
        "errors.messages.too_bigfile",
        filename: file.name, filesize: file.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
      message2 = I18n.t(
        "errors.messages.too_bigsize",
        total: file.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
      checker.errors[:base].tap do |errors|
        expect(errors).to have(2).items
        expect(errors[0]).to eq message1
        expect(errors[1]).to eq message2
      end
    end

    it "mobile_size 100" do
      site.mobile_state = "enabled"
      site.mobile_size = 100 * 1_024
      site.save!
      site.reload

      html = ""
      html += "<img src=\"/fs/#{file.id}/_/logo.png\">"

      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
      expect(checker.errors[:base]).to be_blank
    end

    it "many same files in html" do
      site.mobile_state = "enabled"
      site.mobile_size = 20 * 1_024
      site.save!
      site.reload

      html = ""
      html += "<img src=\"/fs/#{file.id}/_/logo.png\">"

      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
      expect(checker.errors[:base]).to be_blank

      3.times.each do
        html += "<img src=\"/fs/#{file.id}/_/logo.png\">"
      end

      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)
      expect(checker.errors[:base]).to be_blank
    end

    it "many different files in html" do
      site.mobile_state = "enabled"
      site.mobile_size = 6 * 1_024
      site.save!
      site.reload

      file2 = tmp_ss_file(
        Cms::File, site: site, user: cms_user, model: Cms::File::FILE_MODEL,
        contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      )

      html = ""
      html += "<img src=\"/fs/#{file.id}/_/logo.png\">"
      html += "<img src=\"/fs/#{file2.id}/_/keyvisual.jpg\">"
      checker = Cms::MobileSizeChecker.check(cur_site: site, cur_user: user, html: html)

      message1 = I18n.t(
        "errors.messages.too_bigfile",
        filename: file.name, filesize: file.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
      message2 = I18n.t(
        "errors.messages.too_bigfile",
        filename: file2.name, filesize: file2.thumb.size.to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
      message3 = I18n.t(
        "errors.messages.too_bigsize",
        total: (file.thumb.size + file2.thumb.size).to_fs(:human_size), mobile_size: site.mobile_size.to_fs(:human_size))
      checker.errors[:base].tap do |errors|
        expect(errors).to have(3).items
        expect(errors[0]).to eq message2
        expect(errors[1]).to eq message1
        expect(errors[2]).to eq message3
      end
    end
  end
end
