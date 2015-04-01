require 'spec_helper'

describe Job::Task do
  describe 'array arg' do
    let(:args) { [ 1, 'message' ] }
    let(:entity) { { name: 'job', class_name: 'Foo', args: [ args ] } }
    let(:item) { Job::Task.create!(entity) }
    subject { Job::Task.find_by(id: item.id) }

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args ] }
    its(:priority) { should be_within(5).of(Time.now.to_i) }
  end

  describe 'symbolized key hash arg' do
    let(:args) { { :id => 1, :payload => 'message'} }
    let(:entity) { { name: 'job', class_name: 'Foo', args: [ args ] } }
    let(:item) { Job::Task.create!(entity) }
    subject { Job::Task.find_by(id: item.id) }

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args.stringify_keys ] }
    its(:priority) { should be_within(5).of(Time.now.to_i) }
  end

  describe 'string key hash arg' do
    let(:args) { { 'id' => 1, 'payload' => 'message'} }
    let(:entity) { { name: 'job', class_name: 'Foo', args: [ args ] } }
    let(:item) { Job::Task.create!(entity) }
    subject { Job::Task.find_by(id: item.id) }

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args.stringify_keys ] }
    its(:priority) { should be_within(5).of(Time.now.to_i) }
  end
end
