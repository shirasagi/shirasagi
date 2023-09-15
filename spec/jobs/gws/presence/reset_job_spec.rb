require 'spec_helper'

describe ::Gws::Presence::ResetJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  context "when presence is blank" do
    before do
      presence = user.user_presence(site)
      presence.reload
      presence.update!(state: '')
    end

    it do
      job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
      job_class.perform_now

      user.user_presence(site).tap do |presence|
        presence.reload
        expect(presence.state).to be_blank
      end
    end
  end

  context "when presence is available" do
    before do
      presence = user.user_presence(site)
      presence.reload
      presence.update!(state: 'available')
    end

    it do
      job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
      job_class.perform_now

      user.user_presence(site).tap do |presence|
        presence.reload
        expect(presence.state).to eq 'unavailable'
      end
    end
  end

  context "when presence is unavailable" do
    before do
      presence = user.user_presence(site)
      presence.reload
      presence.update!(state: 'unavailable')
    end

    it do
      job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
      job_class.perform_now

      user.user_presence(site).tap do |presence|
        presence.reload
        expect(presence.state).to eq 'unavailable'
      end
    end
  end

  context "when presence is leave" do
    before do
      presence = user.user_presence(site)
      presence.reload
      presence.update!(state: 'leave')
    end

    it do
      job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
      job_class.perform_now

      user.user_presence(site).tap do |presence|
        presence.reload
        expect(presence.state).to eq 'leave'
      end
    end
  end

  context "when presence is dayoff" do
    before do
      presence = user.user_presence(site)
      presence.reload
      presence.update!(state: 'dayoff')
    end

    it do
      job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
      job_class.perform_now

      user.user_presence(site).tap do |presence|
        presence.reload
        expect(presence.state).to eq 'dayoff'
      end
    end
  end
end
