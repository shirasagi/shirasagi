FactoryGirl.define do
  factory :public_board_node_post, class: PublicBoard::Node::Post, traits: [:cms_node] do
    route "public_board/post"
  end
end
