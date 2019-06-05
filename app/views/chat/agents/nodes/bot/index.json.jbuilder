json.text(@result)
json.suggest(@intent.try(:suggest).presence)
json.question(@cur_node.becomes_with_route.question) if @intent.present?
