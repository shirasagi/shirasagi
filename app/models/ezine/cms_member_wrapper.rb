# this class provides compatible methods of Cms::Member
class Ezine::CmsMemberWrapper
  include Cms::Model::Member
  include Ezine::Addon::Subscription

  def test_member?
    false
  end
end
