require 'spec_helper'

describe "contact/agents/addons/page/view/index.html.erb", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let(:layout) { create_cms_layout(cur_site: site) }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout, page_layout: layout }

  context "when page's contact_state is 'hide'" do
    let!(:group) do
      create(
        :contact_group, name: "#{group0.name}/#{unique_id}",
        contact_groups: [
          {
            name: "name-#{unique_id}",
            contact_group_name: "name-#{unique_id}", contact_charge: "charge-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
            main_state: "main"
          }
        ]
      )
    end
    let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

    let!(:article) do
      page = create(
        :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "hide",
        contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
      ::FileUtils.rm_f(page.path)
      page
    end

    it do
      visit article.full_url
      expect(page).to have_no_css("footer.contact")
    end
  end

  context "when page's contact_state is 'show'" do
    context "when all conteact attributes are blank" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil, contact_tel: nil, contact_fax: nil,
              contact_email: nil, contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        # 表示項目数が部署名の1個の場合、全体的に非表示となる。
        expect(page).to have_no_css("footer.contact")
      end
    end

    context "when only contact_group_name is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: "name-#{unique_id}", contact_charge: nil,
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        # 表示項目数が部署名の1個の場合、全体的に非表示となる。
        expect(page).to have_no_css("footer.contact")
      end
    end

    context "when only contact_charge is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: "charge-#{unique_id}",
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定した担当部署・係が表示される
          expect(page).to have_css(".charge", text: main_contact.contact_charge)
        end
      end
    end

    context "when only contact_group_name and contact_charge are given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: "name-#{unique_id}", contact_charge: "charge-#{unique_id}",
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: main_contact.contact_group_name)
          # グループに設定した担当部署・係が表示される
          expect(page).to have_css(".charge", text: main_contact.contact_charge)
        end
      end
    end

    context "when only contact_group_name and contact_charge are same" do
      let!(:group) do
        same_name = "name-#{unique_id}"
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: same_name, contact_charge: same_name,
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        # 部署名と担当部署名・係名が同じ場合、担当部署名・係名は表示されない。この結果、表示項目数が1個となり、全体的に非表示となる。
        expect(page).to have_no_css("footer.contact")
      end
    end

    context "when only contact_tel is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: unique_tel, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したTELが表示される
          expect(page).to have_css(".tel", text: main_contact.contact_tel)
        end
      end
    end

    context "when only contact_fax is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: nil, contact_fax: unique_tel, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したFAXが表示される
          expect(page).to have_css(".fax", text: main_contact.contact_fax)
        end
      end
    end

    context "when only contact_tel is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: unique_tel, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したTELが表示される
          expect(page).to have_css(".tel", text: main_contact.contact_tel)
        end
      end
    end

    context "when only contact_email is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: nil, contact_fax: nil, contact_email: unique_email,
              contact_link_url: nil, contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したメールアドレスが表示される
          expect(page).to have_css(".email", text: main_contact.contact_email)
        end
      end
    end

    context "when only contact_link_url is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: "/#{unique_id}", contact_link_name: nil,
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したメールアドレスが表示される
          expect(page).to have_css(".link", text: group.section_name)
        end
      end
    end

    context "when only contact_link_name is given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: nil, contact_link_name: "link_name-#{unique_id}",
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        # リンク名だけでは意味がない。リンクURLが未設定の場合、何も表示されない。
        # この結果、表示項目数が1個となり、全体的に非表示となる。
        expect(page).to have_no_css("footer.contact")
      end
    end

    context "when only contact_link_url and contact_link_name are given" do
      let!(:group) do
        create(
          :contact_group, name: "#{group0.name}/#{unique_id}",
          contact_groups: [
            {
              name: "name-#{unique_id}", contact_group_name: nil, contact_charge: nil,
              contact_tel: nil, contact_fax: nil, contact_email: nil,
              contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
              main_state: "main"
            }
          ]
        )
      end
      let!(:main_contact) { group.contact_groups.where(main_state: "main").first }

      let!(:article) do
        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, contact_state: "show",
          contact_group: group, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
        ::FileUtils.rm_f(page.path)
        page
      end

      it do
        visit article.full_url
        within "footer.contact" do
          # 既定のセクション名が表示される
          expect(page).to have_css(".group", text: group.section_name)
          # グループに設定したメールアドレスが表示される
          expect(page).to have_css(".link", text: main_contact.contact_link_name)
        end
      end
    end
  end
end
