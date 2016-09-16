class Recommend::History::Recommender < Recommendify::Base
  max_neighbors 50

  input_matrix :order_items,
    #:native => true,
    :similarity_func => :jaccard,
    :weight => 5.0
end
