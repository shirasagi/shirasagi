require 'spec_helper'
require 'json'

def create_task(*args)
  # puts args.class.to_s
  # puts args

  hash = { 'class_name' => 'Foo', 'args' => args }
  hash = hash.merge({ 'name' => 'job' })
  task = Job::Model.create(hash.stringify_keys)
  task.id
end

describe Job::Model do
  describe 'array arg' do
    expected_priority = Time.now.to_i
    args = [ 1, 'message' ]
    subject_id = create_task(args)

    subject do
      Job::Model.find_by(id: subject_id)
    end

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args ] }
    its(:priority) { should be_within(5).of(expected_priority) }
  end

  describe 'symbolized key hash arg' do
    expected_priority = Time.now.to_i
    args = { :id => 1, :payload => 'message'}
    subject_id = create_task(args)

    subject do
      Job::Model.find_by(id: subject_id)
    end

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args.stringify_keys ] }
    its(:priority) { should be_within(5).of(expected_priority) }
  end

  describe 'string key hash arg' do
    expected_priority = Time.now.to_i
    args = { 'id' => 1, 'payload' => 'message'}
    subject_id = create_task(args)

    subject do
      Job::Model.find_by(id: subject_id)
    end

    it { should_not be_nil }
    its(:name) { should eq 'job' }
    its(:class_name) { should eq 'Foo' }
    its(:args) { should eq [ args.stringify_keys ] }
    its(:priority) { should be_within(5).of(expected_priority) }
  end
end
