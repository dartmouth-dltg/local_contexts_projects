require 'net/http'
require 'aspace_logger'

class LocalContextsClient

  def initialize
    @base_url = AppConfig[:local_contexts_base_url]
    @api_version_path = AppConfig[:local_contexts_api_path]
    @query_data_type = '?format=json'
    @api_paths_map = {
      "project" => "projects",
      "user" => "users",
      "researcher" => "researchers",
      "institution" => "institutions"
    }
  end


  def maybe_parse_json(response)
    begin
      ASUtils.json_parse(response.body)
    rescue JSON::ParserError
      Log.error("Couldn't parse response as JSON: #{response.inspect} -- #{response.body}")
      raise ReferenceError.new("Unrecognized response from Local Conexts API")
    end
  end


  def get(suffix, headers = {})
    get_url = url(suffix)

    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      headers.each {|k,v| req[k] = v }

      response = http.request(req)

      if response.code != "200"
        raise ConflictException.new("Failure in GET request from Local Contexts: #{response.body}")
      end

      response
    end
  end


  def get_json(suffix)
    res = get(suffix)
    maybe_parse_json(res)
  end


  def get_data_from_api(id, type)
    lc_api_path_for_type = File.join(@api_paths_map[type], id)
    get_json(lc_api_path_for_type)
  end

  private

  def url(suffix, params = {})
    URI(File.join(@base_url, @api_version_path, suffix, @query_data_type))
  end

  def http_request(url)
    Net::HTTP.start(url.host, url.port,
                    :use_ssl => url.scheme == 'https',
                    :read_timeout => 60,
                    :open_timeout => 60,
                    :ssl_timeout => 60) do |http|
      yield(http)
    end
  end

end
