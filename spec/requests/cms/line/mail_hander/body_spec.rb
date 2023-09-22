require 'spec_helper'

describe "Cms::Agents::Nodes::LineHubController", type: :request, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node)   { create :cms_node_line_hub, layout_id: layout.id, filename: "receiver" }

  let(:from_conditions) { %w(sample@example.jp) }
  let(:to_conditions) { %w(example.jp) }
  let(:mail_handler) do
    create(:cms_line_mail_handler, handle_state: "deliver", deliver_condition_state: "broadcast",
      from_conditions: from_conditions, to_conditions: to_conditions,
      subject_state: subject_state, start_line: start_line, terminate_line: terminate_line)
  end
  let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }
  let(:message) { Cms::Line::Message.site(site).last }

  context "public" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!

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

      context "deliver handler" do
        context "post utf-8 mail" do
          let(:file) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }
          let(:decoded) { "【UTF-8】\n\nシラサギ役場よりお知らせします。\n暴風警報が発表されました。" }
          let(:start_line) { "【緊急メールサービス】" }
          let(:terminate_line) { "農業用施設等につきましては、十分な管理をお願いします。" }
          let(:subject_state) { "include" }

          it "#mail" do
            mail_handler
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: file }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "completed"
              expect(capture.broadcast.count).to eq 1
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
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
            mail_handler
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: file }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "completed"
              expect(capture.broadcast.count).to eq 1
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
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
            mail_handler
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: file }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "completed"
              expect(capture.broadcast.count).to eq 1
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
            end
          end
        end
      end
    end
  end
end
