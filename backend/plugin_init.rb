require_relative 'lib/local_context_ead'

unless AppConfig.has_key?(:local_context_base_url)
  AppConfig[:local_context_base_url] = "https://localcontextshub.org/"
end

AppConfig[:local_context_api_path] = "api/v1"
