require "loofah"

Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.clear
Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.add("http")
Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.add("https")
