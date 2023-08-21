require 'spec_helper'

describe Gws::Workflow::File, type: :model, dbscope: :example do
  context "empty" do
    subject { described_class.new }
    its(:valid?) { is_expected.to be_falsey }
  end

  context "factory girl" do
    subject { create :gws_workflow_file }
    its(:valid?) { is_expected.to be_truthy }
  end
end
