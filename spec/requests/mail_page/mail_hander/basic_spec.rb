require 'spec_helper'

describe "MailPage::Agents::Nodes::PageController", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) do
    create :mail_page_node_page, layout: create_cms_layout, filename: "node2", arrival_days: rand(1..5),
    mail_page_from_conditions: ["sample@example.jp"],
    mail_page_to_conditions: ["sample@example.jp"]
  end
  let!(:url) { "http://#{site.domain}/#{node.url}mail" }
  let(:page) { MailPage::Page.site(site).last }

  let(:decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/decoded") }
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

    context "without api_token" do
      context "post utf-8 mail" do
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

        it "#mail" do
          expect { post(url, params: { data: data }) }.to raise_error "404"
          expect(MailPage::Page.count).to eq 0
        end
      end

      context "post iso-2022-jp mail" do
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

        it "#mail" do
          expect { post(url, params: { data: data }) }.to raise_error "404"
          expect(MailPage::Page.count).to eq 0
        end
      end
    end

    context "with api_token" do
      let!(:api_token) { create :cms_api_token }
      let!(:headers) { { SS::ApiToken::API_KEY_HEADER => api_token.to_jwt } }

      context "post utf-8 mail" do
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

        it "#mail" do
          perform_enqueued_jobs do
            post url, params: { data: data }, headers: headers
            expect(MailPage::Page.count).to eq 1
            expect(page.html.gsub("<br />", "\n")).to eq decoded
          end
        end
      end

      context "post iso-2022-jp mail" do
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

        it "#mail" do
          perform_enqueued_jobs do
            post url, params: { data: data }, headers: headers
            expect(MailPage::Page.count).to eq 1
            expect(page.html.gsub("<br />", "\n")).to eq decoded
          end
        end
      end
    end
  end
end
