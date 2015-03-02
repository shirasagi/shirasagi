require 'spec_helper'

describe Workflow::Route do
  describe "#approvers" do
    context "when csv is given" do
      subject { Workflow::Route.new({ approvers: [ "", "1,2", "2,1", "1,2" ] }) }
      it { expect(subject.approvers.length).to eq 2 }
      it { expect(subject.approvers[0][:level]).to eq 1 }
      it { expect(subject.approvers[0][:user_id]).to eq 2 }
      it { expect(subject.approvers[1][:level]).to eq 2 }
      it { expect(subject.approvers[1][:user_id]).to eq 1 }
    end

    context "when array of hash is given" do
      subject do
        approvers = [
          nil,
          { level: 1, user_id: 2 },
          { level: 2, user_id: 1 },
          { level: 1, user_id: 2 } ]
        Workflow::Route.new({ approvers: approvers })
      end
      it { expect(subject.approvers.length).to eq 2 }
      it { expect(subject.approvers[0][:level]).to eq 1 }
      it { expect(subject.approvers[0][:user_id]).to eq 2 }
      it { expect(subject.approvers[1][:level]).to eq 2 }
      it { expect(subject.approvers[1][:user_id]).to eq 1 }
    end
  end

  describe "#required_counts" do
    context "when csv is given" do
      subject do
        Workflow::Route.new({ required_counts: %w(false 1 2) })
      end
      it { expect(subject.required_counts.length).to eq 3 }
      it { expect(subject.required_counts[0]).to be false }
      it { expect(subject.required_counts[1]).to eq 1 }
      it { expect(subject.required_counts[2]).to eq 2 }
    end

    context "when array is given" do
      subject do
        Workflow::Route.new({ required_counts: [ false, 1, 2 ] })
      end
      it { expect(subject.required_counts.length).to eq 3 }
      it { expect(subject.required_counts[0]).to be false }
      it { expect(subject.required_counts[1]).to eq 1 }
      it { expect(subject.required_counts[2]).to eq 2 }
    end
  end

  describe "#validate" do
    context "when name is missing" do
      subject do
        Workflow::Route.new({ group_ids: [ 1 ],
                              approvers: [ "", "1,2", "2,1", "1,2" ],
                              required_counts: %w(false 1 2) })
      end
      it { expect(subject).to have(1).errors_on(:name) }
    end

    context "when group_ids is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              approvers: [ "", "1,2", "2,1", "1,2" ],
                              required_counts: %w(false 1 2) })
      end
      it { expect(subject).to have(1).errors_on(:group_ids) }
    end

    context "when approvers is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              required_counts: %w(false 1 2) })
      end
      it { expect(subject).to have(1).errors_on(:approvers) }
    end

    context "when required_counts is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              approvers: [ "", "1,2", "2,1", "1,2" ] })
      end
      it { expect(subject).to have(1).errors_on(:required_counts) }
    end

    context "when approvers's level is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              approvers: [ { user_id: 2 }, { user_id: 1 } ],
                              required_counts: [ false, false ] })
      end
      it { expect(subject).to have(2).errors_on(:base) }
    end

    context "when approvers's user_id is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              approvers: [ { level: 1 }, { level: 2 } ],
                              required_counts: [ false, false ] })
      end
      it { expect(subject).to have(2).errors_on(:base) }
    end

    context "when 1st level is missing" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              approvers: [ { level: 2, user_id: 1 } ],
                              required_counts: [ false, false ] })
      end
      it { expect(subject).to have(1).errors_on(:base) }
    end

    context "when approvers is less than required count" do
      subject do
        Workflow::Route.new({ name: "workflow-#{rand(0x100000000).to_s(36)}",
                              group_ids: [ 1 ],
                              approvers: [ { level: 1, user_id: 2 } ],
                              required_counts: [ 2 ] })
      end
      it { expect(subject).to have(1).errors_on(:required_counts) }
    end
  end

  describe "#search" do
    context "when nil is given" do
      subject { Workflow::Route.search(nil) }
      it { expect(subject).not_to be_nil }
      it { expect(subject.count).to eq 0 }
    end

    context "when name is given" do
      subject do
        Workflow::Route.search({ name: rand(0x100000000).to_s(36) })
      end
      it { expect(subject).not_to be_nil }
      it { expect(subject.count).to eq 0 }
    end

    context "when keyword is given" do
      subject do
        Workflow::Route.search({ keyword: rand(0x100000000).to_s(36) })
      end
      it { expect(subject).not_to be_nil }
      it { expect(subject.count).to eq 0 }
    end
  end
end
