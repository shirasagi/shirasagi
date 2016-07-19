require 'spec_helper'

describe 'members/agents/nodes/my_group', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id }
  let(:group_invitation_template) do
    %w(
      #{sender_name} さんがあなたをグループへ招待しました。
      #{invitation_message}
      グループに参加する場合は、下の URL をクリックしてください。
      #{accept_url}
    ).join("\n")
  end
  let(:group_invitation_signature) do
    %w(
      ====
      シラサギ市 グループ招待
    ).join("\n")
  end
  let(:member_invitation_template) do
    %w(
      #{sender_name} さんがあなたを招待しました。
      #{invitation_message}
      会員登録する場合は、下の URL をクリックしてください。
      #{registration_url}
    ).join("\n")
  end
  let(:member_invitation_signature) do
    %w(
      ====
      シラサギ市 会員招待
    ).join("\n")
  end
  let(:node_my_group) do
    create(
      :member_node_my_group,
      cur_site: site,
      cur_node: node_mypage,
      layout_id: layout.id,
      sender_name: 'グループ登録',
      sender_email: 'admin@example.jp',
      group_invitation_subject: 'グループ招待',
      group_invitation_template: group_invitation_template,
      group_invitation_signature: group_invitation_signature,
      member_invitation_subject: '会員招待',
      member_invitation_template: member_invitation_template,
      member_invitation_signature: member_invitation_signature,
      member_joins_to_invited_group: 'auto')
  end
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      form_auth: 'enabled',
      redirect_url: node_my_group.url)
  end
  let!(:node_registration) do
    create(
      :member_node_registration,
      cur_site: site,
      layout_id: layout.id,
      sender_name: '会員登録',
      sender_email: 'admin@example.jp')
  end
  let(:index_url) { node_my_group.full_url }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  describe 'without member login' do
    it do
      visit index_url

      within 'form.form-login' do
        expect(page).to have_css('input#item_email')
        expect(page).to have_css('input#item_password')
      end
    end
  end

  describe 'with member login' do
    before do
      login_member(site, node_login)
    end

    after do
      logout_member(site, node_login)
    end

    describe 'create new group with inviting non-member' do
      let(:group_name) { unique_id }
      let(:invitation_message) { unique_id }
      let(:invitee_email) { "#{unique_id}@example.jp" }
      let(:invitee_name) { unique_id }
      let(:invitee_password) { 'abc123' }
      let(:invitee_kana) { unique_id }
      let(:invitee_tel) { unique_id }
      let(:invitee_postal_code) { unique_id }
      let(:invitee_addr) { unique_id }
      let(:invitee_sex) { 'female' }
      let(:invitee_era) { '西暦' }
      let(:invitee_birthday) { Date.parse('1988-10-25') }

      it do
        visit index_url

        click_link '新規作成'

        within 'form div.member-my-group-new' do
          expect(page).to have_css('dl.admin dd', text: cms_member.name)
          fill_in 'item[name]', with: group_name
          fill_in 'item[invitation_message]', with: invitation_message
          fill_in 'item[in_invitees]', with: invitee_email

          click_button '保存'
        end

        expect(page).to have_css('td.name', text: group_name)
        expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
        expect(page).to have_css('td.state span.user', text: 'ユーザー: 0 人')
        expect(page).to have_css('td.state span.invitee', text: '招待中: 1 人')

        expect(Member::Group.site(site).count).to eq 1
        group = Member::Group.site(site).first
        expect(group.name).to eq group_name
        expect(group.invitation_message).to eq invitation_message
        expect(group.members.count).to eq 2

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq 'admin@example.jp'
        expect(mail.to.first).to eq invitee_email
        expect(mail.subject).to eq '会員招待'
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(cms_member.name)
        expect(mail.body.raw_source).to include(invitation_message)
        expect(mail.body.raw_source).to include(member_invitation_signature)

        mail.body.raw_source =~ /(#{Regexp.escape(node_registration.full_url)}[^ \t\r\n]+)/
        url = $1
        expect(url).not_to be_nil
        visit url

        within "form div.cms-member-registration-verify" do
          expect(page.find("input[name='group']", visible: false).value).not_to be_nil

          fill_in "item[name]", with: invitee_name
          expect(page).to have_css(".colum dd", text: invitee_email)

          fill_in "item[kana]", with: invitee_kana
          fill_in "item[tel]", with: invitee_tel
          fill_in "item[postal_code]", with: invitee_postal_code
          fill_in "item[addr]", with: invitee_addr
          choose "item_sex_#{invitee_sex}"
          select invitee_era, from: "item[in_birth][era]"
          fill_in "item[in_birth][year]", with: invitee_birthday.year
          select invitee_birthday.month, from: "item[in_birth][month]"
          select invitee_birthday.day, from: "item[in_birth][day]"
          fill_in "item[in_password]", with: invitee_password
          fill_in "item[in_password_again]", with: invitee_password

          click_button "登録"
        end

        visit index_url

        within 'div.member-my-group' do
          expect(page).to have_css('td.name', text: group_name)
          expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
          expect(page).to have_css('td.state span.user', text: 'ユーザー: 1 人')
          expect(page).to have_css('td.state span.invitee', text: '招待中: 0 人')
        end

        click_link group_name

        group.reload
        within 'div.member-my-group-show' do
          expect(page).to have_css('dl.name dd', text: group_name)
          expect(page).to have_css('dl.invitation-message dd', text: invitation_message)

          group.members.each do |member|
            expect(page).to have_css("tr.member-#{member.id} td.name", text: member.member.name)
            expect(page).to have_css("tr.member-#{member.id} td.state", text: member.label(:state))
          end
        end
      end
    end

    describe 'create new group with inviting existing member and accept group invitation as invitee' do
      let(:group_name) { unique_id }
      let(:invitation_message) { unique_id }
      let(:invitee) { create(:cms_member) }

      it do
        visit index_url

        click_link '新規作成'

        within 'form div.member-my-group-new' do
          expect(page).to have_css('dl.admin dd', text: cms_member.name)
          fill_in 'item[name]', with: group_name
          fill_in 'item[invitation_message]', with: invitation_message
          fill_in 'item[in_invitees]', with: invitee.email

          click_button '保存'
        end

        expect(page).to have_css('td.name', text: group_name)
        expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
        expect(page).to have_css('td.state span.user', text: 'ユーザー: 0 人')
        expect(page).to have_css('td.state span.invitee', text: '招待中: 1 人')

        expect(Member::Group.site(site).count).to eq 1
        group = Member::Group.site(site).first
        expect(group.name).to eq group_name
        expect(group.invitation_message).to eq invitation_message
        expect(group.members.count).to eq 2

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq 'admin@example.jp'
        expect(mail.to.first).to eq invitee.email
        expect(mail.subject).to eq 'グループ招待'
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(cms_member.name)
        expect(mail.body.raw_source).to include(invitation_message)
        expect(mail.body.raw_source).to include(group_invitation_signature)

        mail.body.raw_source =~ /(#{Regexp.escape(node_my_group.full_url)}[^ \t\r\n]+\/accept)/
        url = $1
        expect(url).not_to be_nil

        logout_member(site, node_login)
        login_member(site, node_login, invitee)

        visit url

        within 'form div.member-my-group-accept' do
          expect(page).to have_css('.name dd', text: group_name)

          click_button '参加する'
        end

        within 'div.member-my-group' do
          expect(page).to have_css('td.name', text: group_name)
          expect(page).to have_css('span.admin', text: '管理者: 1 人')
          expect(page).to have_css('span.user', text: 'ユーザー: 1 人')
        end

        logout_member(site, node_login, invitee)
        login_member(site, node_login)

        visit index_url

        within 'div.member-my-group' do
          expect(page).to have_css('td.name', text: group_name)
          expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
          expect(page).to have_css('td.state span.user', text: 'ユーザー: 1 人')
          expect(page).to have_css('td.state span.invitee', text: '招待中: 0 人')
        end

        click_link group_name

        group.reload
        within 'div.member-my-group-show' do
          expect(page).to have_css('dl.name dd', text: group_name)
          expect(page).to have_css('dl.invitation-message dd', text: invitation_message)

          group.members.each do |member|
            expect(page).to have_css("tr.member-#{member.id} td.name", text: member.member.name)
            expect(page).to have_css("tr.member-#{member.id} td.state", text: member.label(:state))
          end
        end
      end
    end

    describe 'create new group, then invite existing member and accept group invitation as invitee' do
      let(:group_name) { unique_id }
      let(:invitation_message) { unique_id }
      let(:invitee) { create(:cms_member) }

      it do
        visit index_url

        click_link '新規作成'

        within 'form div.member-my-group-new' do
          expect(page).to have_css('dl.admin dd', text: cms_member.name)
          fill_in 'item[name]', with: group_name
          fill_in 'item[invitation_message]', with: invitation_message

          click_button '保存'
        end

        expect(page).to have_css('td.name', text: group_name)
        expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
        expect(page).to have_css('td.state span.user', text: 'ユーザー: 0 人')
        expect(page).to have_css('td.state span.invitee', text: '招待中: 0 人')

        expect(Member::Group.site(site).count).to eq 1
        group = Member::Group.site(site).first
        expect(group.name).to eq group_name
        expect(group.invitation_message).to eq invitation_message
        expect(group.members.count).to eq 1

        click_link group_name
        click_link '招待する'

        within 'form div.member-my-group-invite' do
          fill_in 'item[in_invitees]', with: invitee.email

          click_button '保存'
        end

        expect(page).to have_css('td.name', text: group_name)
        expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
        expect(page).to have_css('td.state span.user', text: 'ユーザー: 0 人')
        expect(page).to have_css('td.state span.invitee', text: '招待中: 1 人')

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq 'admin@example.jp'
        expect(mail.to.first).to eq invitee.email
        expect(mail.subject).to eq 'グループ招待'
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(cms_member.name)
        expect(mail.body.raw_source).to include(invitation_message)
        expect(mail.body.raw_source).to include(group_invitation_signature)

        mail.body.raw_source =~ /(#{Regexp.escape(node_my_group.full_url)}[^ \t\r\n]+\/accept)/
        url = $1
        expect(url).not_to be_nil

        logout_member(site, node_login)
        login_member(site, node_login, invitee)

        visit url

        within 'form div.member-my-group-accept' do
          expect(page).to have_css('.name dd', text: group_name)

          click_button '参加する'
        end

        within 'div.member-my-group' do
          expect(page).to have_css('td.name', text: group_name)
          expect(page).to have_css('span.admin', text: '管理者: 1 人')
          expect(page).to have_css('span.user', text: 'ユーザー: 1 人')
        end

        logout_member(site, node_login, invitee)
        login_member(site, node_login)

        visit index_url

        within 'div.member-my-group' do
          expect(page).to have_css('td.name', text: group_name)
          expect(page).to have_css('td.state span.admin', text: '管理者: 1 人')
          expect(page).to have_css('td.state span.user', text: 'ユーザー: 1 人')
          expect(page).to have_css('td.state span.invitee', text: '招待中: 0 人')
        end

        click_link group_name

        group.reload
        within 'div.member-my-group-show' do
          expect(page).to have_css('dl.name dd', text: group_name)
          expect(page).to have_css('dl.invitation-message dd', text: invitation_message)

          group.members.each do |member|
            expect(page).to have_css("tr.member-#{member.id} td.name", text: member.member.name)
            expect(page).to have_css("tr.member-#{member.id} td.state", text: member.label(:state))
          end
        end
      end
    end
  end
end
