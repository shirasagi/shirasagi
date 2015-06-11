require 'spec_helper'

describe Workflow::Addon::Approver do
  model = Struct.new("M#{rand(0x100000000).to_s(36)}") do
    include Cms::Model::Page
    include Workflow::Addon::Approver
  end

  describe "#workflow_approvers" do
    context "when csv is given" do
      subject { model.new({ workflow_approvers: [ "", "1,2,pending,", "2,1,pending," ] }) }
      it { expect(subject.workflow_approvers.size).to eq 2 }
      it { expect(subject.workflow_approvers[0][:level]).to eq 1 }
      it { expect(subject.workflow_approvers[0][:user_id]).to eq 2 }
      it { expect(subject.workflow_approvers[0][:state]).to eq "pending" }
      it { expect(subject.workflow_approvers[0][:comment]).to eq "" }
      it { expect(subject.workflow_approvers[1][:level]).to eq 2 }
      it { expect(subject.workflow_approvers[1][:user_id]).to eq 1 }
      it { expect(subject.workflow_approvers[1][:state]).to eq "pending" }
      it { expect(subject.workflow_approvers[1][:comment]).to eq "" }
    end

    context "when hash array is given" do
      subject do
        model.new({ workflow_approvers: [
          nil,
          { level: 1, user_id: 2, state: "pending", comment: "" },
          { level: 2, user_id: 1, state: "pending", comment: "" } ] })
      end
      it { expect(subject.workflow_approvers.size).to eq 2 }
      it { expect(subject.workflow_approvers[0][:level]).to eq 1 }
      it { expect(subject.workflow_approvers[0][:user_id]).to eq 2 }
      it { expect(subject.workflow_approvers[0][:state]).to eq "pending" }
      it { expect(subject.workflow_approvers[0][:comment]).to eq "" }
      it { expect(subject.workflow_approvers[1][:level]).to eq 2 }
      it { expect(subject.workflow_approvers[1][:user_id]).to eq 1 }
      it { expect(subject.workflow_approvers[1][:state]).to eq "pending" }
      it { expect(subject.workflow_approvers[1][:comment]).to eq "" }
    end
  end

  describe "#workflow_required_counts" do
    context "when csv is given" do
      subject { model.new({ workflow_required_counts: %w(false 1 2) }) }
      it { expect(subject.workflow_required_counts.length).to eq 3 }
      it { expect(subject.workflow_required_counts[0]).to be false }
      it { expect(subject.workflow_required_counts[1]).to eq 1 }
      it { expect(subject.workflow_required_counts[2]).to eq 2 }
    end

    context "when array is given" do
      subject { model.new({ workflow_required_counts: [ false, 1, 2 ] }) }
      it { expect(subject.workflow_required_counts.length).to eq 3 }
      it { expect(subject.workflow_required_counts[0]).to be false }
      it { expect(subject.workflow_required_counts[1]).to eq 1 }
      it { expect(subject.workflow_required_counts[2]).to eq 2 }
    end
  end

  describe "#state" do
    context "when state is 'closed'" do
      context "when workflow_state is 'request'" do
        subject { model.new({ state: "closed", workflow_state: "request" }) }
        it { expect(subject.status).to eq "request" }
      end

      context "when workflow_state is 'approve'" do
        subject { model.new({ state: "closed", workflow_state: "approve" }) }
        it { expect(subject.status).to eq "approve" }
      end

      context "when workflow_state is 'pending'" do
        subject { model.new({ state: "closed", workflow_state: "pending" }) }
        it { expect(subject.status).to eq "pending" }
      end

      context "when workflow_state is 'remand'" do
        subject { model.new({ state: "closed", workflow_state: "remand" }) }
        it { expect(subject.status).to eq "remand" }
      end

      context "when workflow_state is missing" do
        subject { model.new({ state: "closed" }) }
        it { expect(subject.status).to eq "closed" }
      end
    end

    context "when state is 'ready'" do
      context "when workflow_state is 'request'" do
        subject { model.new({ state: "ready", workflow_state: "request" }) }
        it { expect(subject.status).to eq "ready" }
      end

      context "when workflow_state is 'approve'" do
        subject { model.new({ state: "ready", workflow_state: "approve" }) }
        it { expect(subject.status).to eq "ready" }
      end

      context "when workflow_state is 'pending'" do
        subject { model.new({ state: "ready", workflow_state: "pending" }) }
        it { expect(subject.status).to eq "ready" }
      end

      context "when workflow_state is 'remand'" do
        subject { model.new({ state: "ready", workflow_state: "remand" }) }
        it { expect(subject.status).to eq "ready" }
      end

      context "when workflow_state is missing" do
        subject { model.new({ state: "ready" }) }
        it { expect(subject.status).to eq "ready" }
      end
    end
  end

  describe "#workflow_current_level" do
    context "when required_count is [ false, false ]" do
      let(:required_counts) { [ false, false ] }
      context "when there is 2 approvers at level 1, 1 approvers at level 2" do
        context "when non of approvers is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,request,", "1,2,request,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when user 1 at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,request,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when user 2 at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,pending,", "1,2,approve,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when all users at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,approve,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when all users at all levels is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,approve,", "2,3,approve," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to be_nil }
          it { expect(subject.finish_workflow?).to be true }
        end
      end
    end

    context "when required_count is [ 1, false ]" do
      let(:required_counts) { [ 1, false ] }
      context "when there is 2 approvers at level 1, 1 approvers at level 2" do
        context "when non of approvers is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,request,", "1,2,request,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when user 1 at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,request,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when user 2 at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,pending,", "1,2,approve,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when all users at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,approve,", "2,3,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
          it { expect(subject.finish_workflow?).to be false }
        end

        context "when user 2 at level 1 is approved, user 3 at level 2 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,pending,", "1,2,approve,", "2,3,approve," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to be_nil }
          it { expect(subject.finish_workflow?).to be true }
        end
      end
    end

    context "when required_count is [ 2, false ]" do
      let(:required_counts) { [ 2, false ] }
      context "when there is 3 approvers at level 1, 1 approvers at level 2" do
        context "when none of approvers is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,request,", "1,2,request,", "1,3,request,", "2,4,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
        end

        context "when 1 user at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,request,", "1,3,request,", "2,4,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 1 }
        end

        context "when 2 users at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,request,", "1,2,approve,", "1,3,approve,", "2,4,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
        end

        context "when all users at level 1 is approved" do
          subject do
            model.new({ workflow_approvers: [ "1,1,approve,", "1,2,approve,", "1,3,approve,", "2,4,pending," ],
                        workflow_required_counts: required_counts})
          end
          it { expect(subject.workflow_current_level).to eq 2 }
        end
      end
    end
  end

  describe "#set_workflow_approver_state_to_request" do
    subject do
      model.new({ workflow_approvers: [ "1,1,pending,", "1,2,pending,", "1,3,pending,", "2,4,pending," ],
                  workflow_required_counts: [ false, false ]})
    end
    it do
      subject.set_workflow_approver_state_to_request
      expect(subject.workflow_approvers[0][:state]).to eq "request"
      expect(subject.workflow_approvers[1][:state]).to eq "request"
      expect(subject.workflow_approvers[2][:state]).to eq "request"
      expect(subject.workflow_approvers[3][:state]).to eq "pending"
    end
  end

  describe "#update_current_workflow_approver_state" do
    context "when user 1 at current level is updated" do
      subject do
        model.new({ workflow_approvers: [ "1,1,pending,", "1,2,pending,", "1,3,pending,", "2,4,pending," ],
                    workflow_required_counts: [ false, false ]})
      end
      it do
        subject.update_current_workflow_approver_state(2, "approve", "LGTM")
        expect(subject.workflow_approvers[0][:state]).to eq "pending"
        expect(subject.workflow_approvers[1][:state]).to eq "approve"
        expect(subject.workflow_approvers[2][:state]).to eq "pending"
        expect(subject.workflow_approvers[3][:state]).to eq "pending"
      end
    end

    context "when user 4 at non-current level is updated" do
      subject do
        model.new({ workflow_approvers: [ "1,1,pending,", "1,2,pending,", "1,3,pending,", "2,4,pending," ],
                    workflow_required_counts: [ false, false ]})
      end
      it do
        subject.update_current_workflow_approver_state(4, "approve", "LGTM")
        expect(subject.workflow_approvers[0][:state]).to eq "pending"
        expect(subject.workflow_approvers[1][:state]).to eq "pending"
        expect(subject.workflow_approvers[2][:state]).to eq "pending"
        # nothing to change
        expect(subject.workflow_approvers[3][:state]).to eq "pending"
      end
    end
  end

  describe "#validate" do
    context "when workflow_approvers is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ ],
                    workflow_required_counts: [ false, false ]})
      end
      it { expect(subject).to have(1).errors_on(:workflow_approvers) }
    end

    context "when workflow_approver's level is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { user_id: 1, state: "request" } ],
                    workflow_required_counts: [ false, false ]})
      end
      it { expect(subject).to have(1).errors_on(:workflow_approvers) }
    end

    context "when workflow_approver's user_id is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { level: 1, state: "request" } ],
                    workflow_required_counts: [ false, false ]})
      end
      it { expect(subject).to have(1).errors_on(:workflow_approvers) }
    end

    context "when workflow_approver's state is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { level: 1, user_id: 1 } ],
                    workflow_required_counts: [ false, false ]})
      end
      it { expect(subject).to have(1).errors_on(:workflow_approvers) }
    end

    context "when level 1 is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { level: 2, user_id: 1, state: "request" } ],
                    workflow_required_counts: [ false, false ]})
      end
      it { expect(subject).to have(1).errors_on(:base) }
      it do
        expect(subject.errors_on(:base)).to \
          include(I18n.t("errors.messages.approvers_level_missing", level: 1))
      end
    end

    context "when workflow_required_counts is missing" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { level: 1, user_id: 1, state: "request" } ],
                    workflow_required_counts: [ ]})
      end
      it { expect(subject).to have(1).errors_on(:workflow_required_counts) }
    end

    context "when workflow_approvers is less than workflow_required_counts" do
      subject do
        model.new({ workflow_state: "request",
                    workflow_approvers: [ { level: 1, user_id: 1, state: "request" } ],
                    workflow_required_counts: [ 2 ]})
      end
      it { expect(subject).to have(1).errors_on(:base) }
      it do
        expect(subject.errors_on(:base)).to \
          include(I18n.t("errors.messages.required_count_greater_than_approvers", level: 1, required_count: 2))
      end
    end
  end
end
