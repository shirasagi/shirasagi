FactoryBot.define do
  factory :board_anpi_post, class: Board::AnpiPost do
    text { "#{unique_id}\n#{unique_id}" }
    public_scope { "group" }
    point { { "loc"=>[139.399852752, 35.712948784], "zoom_level"=>11 } }
  end
end
