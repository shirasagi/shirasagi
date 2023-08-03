require 'spec_helper'

describe "Cms::Agents::Nodes::LineHubController", type: :request, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node)   { create :cms_node_line_hub, layout_id: layout.id, filename: "receiver" }

  let(:from_conditions) { %w(sample@example.jp) }
  let(:to_conditions) { %w(example.jp) }

  let(:decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/decoded") }
  let(:message) { Cms::Line::Message.site(site).last }

  context "public" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!

      Capybara.app_host = "http://#{site.domain}"
    end

    context "without api_token" do
      context "deliver handler" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "deliver", deliver_condition_state: "broadcast",
            from_conditions: from_conditions, to_conditions: to_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }

        context "post utf-8 mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              expect { post url, params: { data: data } }.to raise_error "404"
              expect(Cms::Line::Message.count).to eq 0
            end
          end
        end
      end
    end

    context "with api_token" do
      let!(:api_token) { create :cms_api_token }
      let!(:headers) { { SS::ApiToken::API_KEY_HEADER => api_token.to_jwt } }

      context "deliver handler" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "deliver", deliver_condition_state: "broadcast",
            from_conditions: from_conditions, to_conditions: to_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }

        context "post utf-8 mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
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
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
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

      context "draft handler" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "draft", deliver_condition_state: "broadcast",
            from_conditions: from_conditions, to_conditions: to_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }

        context "post utf-8 mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "draft"
              expect(capture.broadcast.count).to eq 0
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 0
            end
          end
        end

        context "post iso-2022-jp mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "draft"
              expect(capture.broadcast.count).to eq 0
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 0
            end
          end
        end
      end

      context "disable handler" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "disabled", deliver_condition_state: "broadcast",
            from_conditions: from_conditions, to_conditions: to_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }

        context "post utf-8 mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

          it "#mail" do
            expect { post(url, params: { data: data }, headers: headers) }.to raise_error "404"
          end
        end

        context "post iso-2022-jp mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

          it "#mail" do
            expect { post url, params: { data: data }, headers: headers }.to raise_error "404"
          end
        end
      end

      context "no handler" do
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{unique_id}" }
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

        it "#mail" do
          expect { post url, params: { data: data }, headers: headers }.to raise_error "404"
        end
      end

      context "from conditions unmatched" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "draft", deliver_condition_state: "broadcast",
            to_conditions: to_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

        it "#mail" do
          expect { post url, params: { data: data }, headers: headers }.to raise_error "from conditions unmatched"
        end
      end

      context "to conditions unmatched" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "draft", deliver_condition_state: "broadcast",
            from_conditions: from_conditions)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }
        let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

        it "#mail" do
          expect { post url, params: { data: data }, headers: headers }.to raise_error "to conditions unmatched"
        end
      end
    end
  end
end
