FactoryGirl.define do
  factory :board_node_post, class: Board::Node::Post, traits: [:cms_node] do
    route "board/post"
  end

  factory :board_node_anpi_post, class: Board::Node::AnpiPost, traits: [:cms_node] do
    route "board/anpi_post"
  end
end
