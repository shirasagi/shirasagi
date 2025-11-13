require 'spec_helper'

describe Cms::Page::MoveService, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create(:cms_node_page, cur_site: site) }
  let(:page) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page1.html") }
  let(:task) { SS::Task.find_or_create_for_model(page, site: site) }

  describe "#move" do
    context "with valid destination" do
      let(:destination) { "#{node.filename}/page2.html" }
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: destination,
          task: task
        )
      end

      it "moves page successfully" do
        expect(service.move).to be_truthy
        expect(service.errors).to be_empty

        page.reload
        expect(page.filename).to eq(destination)
      end
    end

    context "with blank destination" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: "",
          task: task
        )
      end

      it "returns false and adds error" do
        expect(service.move).to be_falsey
        expect(service.errors).to be_present
      end
    end

    context "with invalid destination" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: "/invalid/path/page.html",
          task: task
        )
      end

      it "returns false and adds error" do
        expect(service.move).to be_falsey
        expect(service.errors).to be_present
      end
    end

    context "with branch page" do
      let(:master_page) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/master.html") }
      let(:branch_page) do
        page = create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/branch.html")
        page.master_id = master_page.id
        page.save!
        page.reload
      end
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: branch_page,
          destination: "#{node.filename}/page2.html",
          task: task
        )
      end

      it "raises error" do
        expect { service.move }.to raise_error("400")
      end
    end

    context "without move permission" do
      let(:no_permission_user) { create(:cms_user, uid: unique_id, name: unique_id, group: cms_group, cms_role_ids: []) }
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: no_permission_user,
          cur_node: node,
          source: page,
          destination: "#{node.filename}/page2.html",
          task: task
        )
      end

      it "raises error" do
        expect { service.move }.to raise_error("403")
      end
    end

    context "without task" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: "#{node.filename}/page2.html",
          task: nil
        )
      end

      it "moves page successfully without logging" do
        expect(service.move).to be_truthy
        page.reload
        expect(page.filename).to eq("#{node.filename}/page2.html")
      end
    end
  end

  describe "#move_page" do
    context "with valid destination" do
      let(:destination) { "#{node.filename}/page2.html" }
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          task: task
        )
      end

      it "returns success result hash" do
        result = service.move_page(page, destination)

        expect(result[:success]).to be_truthy
        expect(result[:errors]).to be_empty
        expect(result[:page_id]).to eq(page.id)
        expect(result[:filename]).to eq(page.filename)
        expect(result[:destination_filename]).to eq(destination)

        page.reload
        expect(page.filename).to eq(destination)
      end
    end

    context "with invalid destination" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          task: task
        )
      end

      it "returns error result hash" do
        result = service.move_page(page, "")

        expect(result[:success]).to be_falsey
        expect(result[:errors]).to be_present
        expect(result[:page_id]).to eq(page.id)
        expect(result[:filename]).to eq(page.filename)
      end
    end

    context "when exception occurs" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          task: task
        )
      end

      before do
        allow(page).to receive(:move).and_raise(StandardError.new("Test error"))
      end

      it "returns error result hash with exception message" do
        result = service.move_page(page, "#{node.filename}/page2.html")

        expect(result[:success]).to be_falsey
        expect(result[:errors]).to include("Test error")
        expect(result[:page_id]).to eq(page.id)
      end
    end
  end

  describe "validation" do
    context "when destination is blank" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: "",
          task: task
        )
      end

      it "is invalid" do
        expect(service.valid?).to be_falsey
        expect(service.errors[:destination]).to be_present
      end
    end

    context "when source validates destination" do
      let(:service) do
        described_class.new(
          cur_site: site,
          cur_user: user,
          cur_node: node,
          source: page,
          destination: "/invalid/path/page.html",
          task: task
        )
      end

      it "copies errors from source" do
        service.valid?
        expect(service.errors).to be_present
      end
    end
  end
end
