require 'spec_helper'

describe Cms::Line::DeliverJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:message) { create :cms_line_message, deliver_condition_state: "multicast_with_no_condition" }
  let!(:template) { create :cms_line_template_text, message: message }
  let!(:members) { Array.new(10) { create(:cms_line_member) } }

  let(:logs) { Cms::SnsPostLog::LineDeliver.site(site).where(source_name: message.name).to_a }
  let(:log_count) { logs.size }
  let(:log_member_ids) { logs.map(&:member_ids).flatten }
  let(:log_multicast_user_ids) { logs.map(&:multicast_user_ids).flatten }

  describe "#perform" do
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

    it do
      capture_line_bot_client do |capture|
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
        expect(log_member_ids).to match_array members.map(&:id)
        expect(log_multicast_user_ids).to match_array members.map(&:oauth_id)
      end
    end
  end
end
