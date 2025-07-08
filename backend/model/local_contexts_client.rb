require 'net/http'
require 'fileutils'
require 'aspace_logger'

class LocalContextsClient

  def initialize
    @base_url = AppConfig[:local_contexts_base_url]
    @api_version_path = AppConfig[:local_contexts_api_path]
    @query_data_type = '?format=json'
    @logger = Logger.new($stderr)

    @api_paths_map = {
      "project" => "projects",
      "multi" => "projects/multi",
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

  def check_json(data, parse_type)
    if parse_type == 'fetch'
      log_msg = "Couldn't parse response as JSON: #{data.inspect} -- #{data.body}"
      error_msg = "Unrecognized response from Local Contexts API"
      data = data.body
    else
      log_msg = "Couldn't parse response as JSON: #{data}"
      error_msg = "Cached file data is not recognized"
    end

    begin
      ASUtils.json_parse(data)
    rescue JSON::ParserError
      @logger.error(log_msg)
      raise ReferenceError.new(error_msg)
    end
  end

  def maybe_parse_json(response)
    check_json(response, 'fetch')
  end

  def maybe_parse_cached_json(response)
    check_json(response, 'cache')
  end

  def do_http_request(suffix, type, api_key = nil, headers = {})
    if AppConfig[:local_contexts_api_path] == 'api/v2'
      headers['X-Api-Key'] = (api_key.nil? || api_key.empty?) ? AppConfig[:local_contexts_api_key] : api_key
    end

    get_url = url(suffix, type)
    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      headers.each {|k,v| req[k] = v }
      response = http.request(req)

      if response.code =~ /^2/
        response 
      else
        error = maybe_parse_json(response)
        @logger.error(error)
        raise ReferenceError.new(error["message"])
      end
    end
  end

  def write_lcp_cache(ids, response)
    parsed_response = ASUtils.json_parse(response.body)

    if parsed_response.kind_of?(Array)
      parsed_response.each do |project|
        cache_file = File.join(AppConfig[:local_contexts_cache_dirname], project['unique_id'] + '.json')
        File.open(cache_file,"w"){ |f| f << ASUtils.to_json(project) }
      end
    else
      cache_file = File.join(AppConfig[:local_contexts_cache_dirname], ids + '.json')
      File.open(cache_file,"w"){ |f| f << response.body }
    end
  end

  def check_disk_cache(cache_file, ids)
    if File.exist?(cache_file)
      maybe_parse_cached_json(File.open(cache_file).read)
    else
      @logger.debug("Failed to fetch Local Contexts data for project: #{ids}")
    end
  end

  def attempt_request(suffix, type, ids, use_cache, ignore_cache_time, api_key, attempts)
    res = do_http_request(suffix, type, api_key)
    if res.respond_to?(:body)
      write_lcp_cache(ids, res)
      unless type == 'multi'
        maybe_parse_json(res)
      end
    else
      @logger.debug("Failed to get new Local Contexts data after cache was found to be stale; using stale cached version for now for project: #{ids}. Attempt: #{attempts}")
      get_json(suffix, type, ids, use_cache, api_key, ignore_cache_time, attempts)
    end
  end

  def get_json(suffix, type, ids, use_cache, api_key = nil, ignore_cache_time = false, attempts = 0)
    attempts += 1
    cache_time = AppConfig[:local_contexts_cache_time]

    unless type == 'multi'
      cache_file = File.join(AppConfig[:local_contexts_cache_dirname], ids + '.json')
    end

    if attempts < 3
      if use_cache
        if type == "open_to_collaborate"
          cache_time = AppConfig[:local_contexts_open_to_collaborate_cache_time]
        end
        if !ignore_cache_time && (!File.exist?(cache_file) || (File.mtime(cache_file) < (Time.now - cache_time)))
          attempt_request(suffix, type, ids, use_cache, true, api_key, attempts)
        else
          check_disk_cache(cache_file, ids)
        end
      else
        attempt_request(suffix, type, ids, use_cache, true, api_key, attempts)
      end
    elsif use_cache
      unless type == 'multi'
        check_disk_cache(cache_file, ids)
      end
    else
      msg = "Failed to fetch updated project information for #{ids}"
      @logger.error(msg)
      {"lcp_fetch_error" => msg}
    end
  end

  def get_data_from_local_contexts_api(ids, type, use_cache = true, api_key = nil)
    if type == 'open_to_collaborate'
      get_json(@api_paths_map[type], type, ids, use_cache, api_key)
    else
      lc_api_path_for_type = File.join(@api_paths_map[type], ids)
      get_json(lc_api_path_for_type, type, ids, use_cache, api_key)
    end
  end

  def reset_cache(project_id, type = "project", api_key = nil)
    get_data_from_local_contexts_api(project_id, type, false, api_key)
  end

  def check_otc_notice_cache(use_cache = true)
    if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true
      @logger.info('Checking cache for Open to Collaborate Notice')
      get_data_from_local_contexts_api('open_to_collaborate', 'open_to_collaborate', use_cache)
    end
  end

  def check_cache
    check_otc_notice_cache
    LocalContextsProject.each_with_index do |lcp, idx|
      if (AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true) || idx != 0
        sleep(AppConfig[:local_contexts_api_wait_time])
      end
      @logger.info("Checking cache for Local Contexts Project Id: #{lcp[:project_id]}")
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

  def add_to_multi_update(lcp, use_cache)
    return true if use_cache == false
    cache_time = AppConfig[:local_contexts_cache_time]
    cache_file = File.join(AppConfig[:local_contexts_cache_dirname], lcp[:project_id] + '.json')
    !File.exist?(cache_file) || (File.mtime(cache_file) < (Time.now - cache_time))
  end

  def check_or_reset_cache_multi(use_cache = true)
    check_otc_notice_cache(use_cache)
    if (AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true) || idx != 0
      sleep(AppConfig[:local_contexts_api_wait_time])
    end
    lcp_multi_cache = {}
    lcp_multi_cache[AppConfig[:local_contexts_api_key]] = []
    LocalContextsProject.each do |lcp|
      next unless add_to_multi_update(lcp, use_cache)
      if lcp[:project_api_key].nil?
        lcp_multi_cache[AppConfig[:local_contexts_api_key]] << lcp[:project_id]
      else
        if lcp_multi_cache[lcp[:project_api_key]].nil?
          lcp_multi_cache[lcp[:project_api_key]] = [lcp[:project_id]]
        else
          lcp_multi_cache[lcp[:project_api_key]] << lcp[:project_id]
        end
      end
    end
    @logger.info("Checking cache for Local Contexts projects: #{lcp_multi_cache.inspect}")
      
    lcp_multi_cache.each do |api_key, projects|
      next if projects.count == 0
      get_data_from_local_contexts_api(projects.join(','), 'multi', false, api_key)
    end
  end

  private

  def url(suffix, type, params = {})
    if type == "open_to_collaborate" && AppConfig[:local_contexts_api_path] == 'api/v1'
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
      @logger.error("Could not connect to the Local Contexts API: #{e}")
    end
  end

end
