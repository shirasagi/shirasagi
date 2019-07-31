json.html(@result)
json.intent_id(@intent.try(:id))
json.suggests(@suggest.presence)
json.question(@cur_node.becomes_with_route.question) if @intent.present?
