require_relative 'lib/local_context_ead'

unless AppConfig.has_key?(:local_context_api_url)
  AppConfig[:local_context_api_url] = "https://localcontextshub.org/api/v1/"
end
