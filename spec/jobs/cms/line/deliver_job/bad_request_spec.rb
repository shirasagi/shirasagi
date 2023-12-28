require 'spec_helper'

describe Cms::Line::DeliverJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:bad_request) { Fs.binread("#{Rails.root}/spec/fixtures/cms/line/response/bad_request") }

  let(:logs) { Cms::SnsPostLog::LineDeliver.site(site).where(source_name: message.name).to_a }
  let(:log_count) { logs.size }
  let(:log_actions) { logs.map(&:action) }
  let(:log_member_ids) { logs.map(&:member_ids).flatten }
  let(:log_multicast_user_ids) { logs.map(&:multicast_user_ids).flatten }
  let(:log_states) { logs.map(&:state) }

  before do
    @save_max_members_to = Cms::Line.max_members_to
    Cms::Line.max_members_to = 4

    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  after do
    Cms::Line.max_members_to = @save_max_members_to
  end

  context "broadcast" do
    let!(:message) { create :cms_line_message, deliver_condition_state: "broadcast" }
    let!(:template) { create :cms_line_template_text, message: message }

    it do
      response = proc do |capture|
        OpenStruct.new(code: "400", body: bad_request)
      end

      capture_line_bot_client(broadcast_response: response) do |capture|
        expect do
          perform_enqueued_jobs do
            message.deliver
          end
        end.to output(include("broadcast to members")).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(capture.broadcast.count).to eq 1
        expect(log_count).to eq 1
        expect(log_actions).to eq %w(broadcast)
        expect(log_member_ids).to eq []
        expect(log_multicast_user_ids).to eq []
        expect(log_states).to eq %w(error)
      end
    end
  end

  context "multicast" do
    let!(:message) { create :cms_line_message, deliver_condition_state: "multicast_with_no_condition" }
    let!(:template) { create :cms_line_template_text, message: message }
    let!(:members) { Array.new(10) { create(:cms_line_member) } }

    it do
      response = proc do |capture|
        OpenStruct.new(code: "400", body: bad_request)
      end

      capture_line_bot_client(multicast_response: response) do |capture|
        expect do
          perform_enqueued_jobs do
            message.deliver
          end
        end.to output(include("multicast to members 0..3", "multicast to members 8..9")).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(capture.multicast.count).to eq 3
        expect(log_count).to eq 3
        expect(log_actions).to eq %w(multicast multicast multicast)
        expect(log_member_ids).to match_array members.map(&:id)
        expect(log_multicast_user_ids).to match_array members.map(&:oauth_id)
        expect(log_states).to eq %w(error error error)
      end
    end
  end
end
