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

  describe ".feed_all_memos" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: "http://#{unique_domain}" }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient0) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient1) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:recipient2) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:file) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:message) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user, state: "public",
        in_to_members: [ recipient0.id ], in_cc_members: [ recipient1.id ], in_bcc_members: [ recipient2.id ],
        file_ids: [file.id]
      )
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_memos }.to output(include("- #{message.subject}\n")).to_stdout
    end
  end
end
