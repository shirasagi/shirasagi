require 'spec_helper'

describe "MailPage::Agents::Nodes::PageController", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) do
    create(:mail_page_node_page, layout: create_cms_layout,
      filename: "node2", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"],
      subject_state: subject_state,
      start_line: start_line,
      terminate_line: terminate_line)
  end
  let!(:url) { "http://#{site.domain}/#{node.url}mail" }
  let(:page) { MailPage::Page.site(site).last }

  let(:utf_8_eml) do
    file = "#{Rails.root}/private/files/mail_page_files/#{Time.zone.now.to_i}"
    Fs.mkdir_p "#{Rails.root}/private/files/mail_page_files"
    Fs.binwrite file, Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml")
    file
  end
  let(:iso_2022_jp_eml) do
    file = "#{Rails.root}/private/files/mail_page_files/#{Time.zone.now.to_i}"
    Fs.mkdir_p "#{Rails.root}/private/files/mail_page_files"
    Fs.binwrite file, Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml")
    file
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "with api_token" do
      let!(:api_token) { create :cms_api_token }
      let!(:headers) do
        {
          "CONTENT_TYPE" => "multipart/form-data",
          SS::ApiToken::API_KEY_HEADER => api_token.to_jwt
        }
      end

      context "post utf-8 mail" do
        let(:file) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }
        let(:decoded) { "【UTF-8】\n\nシラサギ役場よりお知らせします。\n暴風警報が発表されました。" }
        let(:start_line) { "【緊急メールサービス】" }
        let(:terminate_line) { "農業用施設等につきましては、十分な管理をお願いします。" }
        let(:subject_state) { "include" }

        it "#mail" do
          perform_enqueued_jobs do
            post url, params: { data: file }, headers: headers
            expect(MailPage::Page.count).to eq 1
            expect(page.html.gsub("<br />", "\n")).to eq decoded
          end
        end
      end

      context "post utf-8_2 mail" do
        let(:file) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/mail_page/UTF-8_2.eml") }
        let(:decoded) do
          [
            "【台風第７号の接近について】",
            "",
            "台風第７号の接近に伴い、本日午後２時に警戒本部を設置しました。",
            "引き続き、気象情報にご注意ください。",
            "",
            "警戒本部",
            "TEL：000-000-0000",
          ].join("\n")
        end
        let(:start_line) { "≪シラサギ市メール配信≫" }
        let(:terminate_line) { "【配信カテゴリ】" }
        let(:subject_state) { "include" }

        it "#mail" do
          perform_enqueued_jobs do
            post url, params: { data: file }, headers: headers
            expect(MailPage::Page.count).to eq 1
            expect(page.html.gsub("<br />", "\n")).to eq decoded
          end
        end
      end

      context "post iso-2022-jp mail" do
        let(:file) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }
        let(:decoded) { "【ISO-2022-JP】\n\nシラサギ役場よりお知らせします。\n暴風警報が発表されました。" }
        let(:start_line) { "【緊急メールサービス】" }
        let(:terminate_line) { "農業用施設等につきましては、十分な管理をお願いします。" }
        let(:subject_state) { "include" }

        it "#mail" do
          perform_enqueued_jobs do
            post url, params: { data: file }, headers: headers
            expect(MailPage::Page.count).to eq 1
            expect(page.html.gsub("<br />", "\n")).to eq decoded
          end
        end
      end
    end
  end
end
