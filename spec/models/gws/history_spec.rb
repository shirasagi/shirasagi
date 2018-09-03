require 'spec_helper'

describe Gws::History, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  describe ".write!" do
    let(:context) { :model }
    let(:item) { create :gws_schedule_plan, cur_site: site, cur_user: user }
    let!(:attributes) do
      {
        mode: 'create', name: item.reference_name, model: item.reference_model, item_id: item.id
      }
    end
    let(:env) do
      { 'rack.session' => OpenStruct.new(id: SecureRandom.uuid), 'action_dispatch.request_id' => SecureRandom.uuid }
    end

    before do
      Rails.application.instance_variable_set(:@current_env, env)
    end

    after do
      Rails.application.instance_variable_set(:@current_env, nil)
    end

    describe ".error!" do
      it do
        expect { described_class.error!(context, user, site, attributes) }.to change { described_class.site(site).count }.by(1)
      end
    end

    describe ".warn!" do
      it do
        expect { described_class.warn!(context, user, site, attributes) }.to change { described_class.site(site).count }.by(1)
      end
    end

    describe ".info!" do
      it do
        expect { described_class.info!(context, user, site, attributes) }.to change { described_class.site(site).count }.by(1)
      end
    end

    describe ".notice!" do
      it do
        expect { described_class.notice!(context, user, site, attributes) }.to change { described_class.site(site).count }.by(0)
      end

      it do
        SS.config.replace_value_at(:gws, :history, { "save_days" => 90, "severity" => "notice", "severity_notice" => "enabled" })
        expect { described_class.notice!(context, user, site, attributes) }.to change { described_class.site(site).count }.by(1)
      end
    end
  end
end
