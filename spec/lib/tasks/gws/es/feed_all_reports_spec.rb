require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end
  end

  describe ".feed_all_reports" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: "http://#{unique_domain}" }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:form) { create(:gws_report_form, cur_site: site, cur_user: user, state: 'public') }
    let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form) }
    let!(:report) { create(:gws_report_file, cur_site: site, cur_user: user, cur_form: form) }

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_reports }.to output(include("- #{report.name}\n")).to_stdout
    end
  end
end
