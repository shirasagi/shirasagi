# The maximum number of parts a request can contain. Accepting to many part
# can lead to the server running out of file handles.
# Set to `0` for no limit.

Rack::Utils.multipart_part_limit = 0
