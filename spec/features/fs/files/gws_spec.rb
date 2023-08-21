require 'spec_helper'

describe "fs_files", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:user1) { create :gws_user, group_ids: user.group_ids }
  let!(:user2) { create :gws_user, group_ids: user.group_ids }
  let!(:file) do
    SS::Sequence.create(id: 'ss_files_id', value: rand(2_000..2_999))
    tmp_ss_file(contents: filename, cur_user: user)
  end

  context "[logo.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    context "file associated to gws/schedule/plan as owner_item" do
      let!(:item) do
        create :gws_schedule_plan, cur_site: site, cur_user: user, file_ids: [ file.id ], member_ids: [ user1.id ]
      end

      context "with user" do
        before { login_gws_user }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end

      context "with member" do
        before { login_user user1 }

        it "via url" do
          visit file.url
          expect(status_code).to eq 200
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 200
        end
      end

      context "with non-member" do
        before { login_user user2 }

        it "via url" do
          visit file.url
          expect(status_code).to eq 404
        end

        it "via thumb_url" do
          visit file.thumb_url
          expect(status_code).to eq 404
        end
      end
    end
  end
end
