FactoryGirl.define do
  factory :board_node_post, class: Board::Node::Post, traits: [:cms_node] do
    route "board/post"
  end
end
