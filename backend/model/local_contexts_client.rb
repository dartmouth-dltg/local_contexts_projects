require 'net/http'
require 'fileutils'
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
      "institution" => "institutions",
      "open_to_collaborate" => "notices/open_to_collaborate"
    }
    @HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Errno::ECONNREFUSED,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ]
  end


  def maybe_parse_json(response)
    begin
      ASUtils.json_parse(response.body)
    rescue JSON::ParserError
      Log.error("Couldn't parse response as JSON: #{response.inspect} -- #{response.body}")
      raise ReferenceError.new("Unrecognized response from Local Contexts API")
    end
  end

  def maybe_parse_cached_json(response)
    begin
      ASUtils.json_parse(response)
    rescue JSON::ParserError
      Log.error("Couldn't parse response as JSON: #{response}")
      raise ReferenceError.new("Cached file data is not recognized")
    end
  end

  def do_http_request(suffix, type, headers = {})
    get_url = url(suffix, type)
    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      headers.each {|k,v| req[k] = v }
      begin
        response = http.request(req)
      rescue => e
        Log.error("Not a valid response from the Local Contexts API: #{e}")
      end

      response
    end
  end

  def write_lcp_cache(cache_file, response)
    if response.body
      File.open(cache_file,"w"){ |f| f << response.body }
    else
      File.open(cache_file,"w"){ |f| f << '' }
    end
  end

  def get_json(suffix, type, id, use_cache, ignore_cache_time = false, attempts = 0)
    attempts += 1
    logger = Logger.new($stderr)
    cache_file = File.join(AppConfig[:local_contexts_cache_dirname], id + '.json')
    cache_time = AppConfig[:local_contexts_cache_time]

    if attempts < 3
      if use_cache
        if type == "open_to_collaborate"
          cache_time = AppConfig[:local_contexts_open_to_collaborate_cache_time]
        end
        if !ignore_cache_time && (!File.exist?(cache_file) || (File.mtime(cache_file) < (Time.now - cache_time)))
          begin
            res = do_http_request(suffix, type)
            write_lcp_cache(cache_file, res)
          rescue => e
            logger.debug("Failed to get new Local Contexts data after cache was found to be stale; using stale cached version for now.")
            get_json(suffix, type, id, use_cache, true, attempts)
          end
        end
        maybe_parse_cached_json(File.open(cache_file).read)
      else
        response = do_http_request(suffix, type)
        if response.respond_to?(:body)      
          logger.debug("getting response: #{response}")
          write_lcp_cache(cache_file, response)
          maybe_parse_json(response)
        else
          logger ("Failed to get new Local Contexts data; trying cached version. Attempt: #{attempts}")
          get_json(suffix, type, id, use_cache, true, attempts)
        end
      end
    else
      if File.exist?(cache_file)
        maybe_parse_cached_json(File.open(cache_file).read)
      else
        logger.debug("Failed to fetch Local Contexts data for new project")
      end
    end
  end

  def get_data_from_local_contexts_api(id, type, use_cache = true)
    if type == 'open_to_collaborate'
      get_json(@api_paths_map[type], type, id, use_cache)
    else
      lc_api_path_for_type = File.join(@api_paths_map[type], id)
      get_json(lc_api_path_for_type, type, id, use_cache)
    end
  end

  def reset_cache(project_id, type = "project")
    get_data_from_local_contexts_api(project_id, type, false)
  end

  def check_cache
    logger = Logger.new($stderr)
    if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true
      logger.info('Checking cache for Open to Collaborate Notice')
      get_data_from_local_contexts_api('open_to_collaborate', 'open_to_collaborate')
    end
    LocalContextsProject.each_with_index do |lcp, idx|
      if (AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true) || idx != 0
        sleep(AppConfig[:local_contexts_api_wait_time])
      end
      logger.info("Checking cache for Local Contexts Project Id: #{lcp[:project_id]}")
      get_data_from_local_contexts_api(lcp[:project_id], 'project')
    end
  end

  def clear_cache(project_id)
    # let's be very careful here
    dir_path = AppConfig[:local_contexts_cache_dirname]
    if dir_path.include?('local_contexts_cache')
      filename = File.join(dir_path, project_id + '.json')
      begin
        File.delete(filename) 
        {"cache_clear_msg" => I18n.t('local_contexts_project._frontend.messages.cache_clear_success')}
      rescue
        {"cache_clear_msg" => I18n.t('local_contexts_project._frontend.messages.cache_clear_error')}
      end
    else
      {"cache_clear_msg" => I18n.t('local_contexts_project._frontend.messages.cache_clear_error')}
    end
  end

  private

  def url(suffix, type, params = {})
    if type == "open_to_collaborate"
      URI(File.join(@base_url, @api_version_path, suffix + @query_data_type))
    else
      URI(File.join(@base_url, @api_version_path, suffix, @query_data_type))
    end
  end

  def http_request(url)
    begin
      Net::HTTP.start(url.host, url.port,
                      :use_ssl => url.scheme == 'https',
                      :read_timeout => 60,
                      :open_timeout => 60,
                      :ssl_timeout => 60) do |http|
        yield(http)
      end
    rescue => e
      Log.error("Could not connect to the Local Contexts API: #{e}")
    end
  end

end
