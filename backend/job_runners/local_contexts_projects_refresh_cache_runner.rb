
class LocalContextsProjectsRefreshCacheRunner < JobRunner

  register_for_job_type('local_contexts_projects_refresh_cache_job')

  def run

    begin
      @job.write_output("Refreshing Local Contexts cache for all Project Ids")
      lcp_client = LocalContextsClient.new
      if AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true
        otc = lcp_client.reset_cache('open_to_collaborate', 'open_to_collaborate')
        if otc['notice_type'] == 'open_to_collaborate'
          @job.write_output(" -> Success refreshing Local Contexts cache for the Open to Collaborate Notice")
        else
          @job.write_output(" -> Error refreshing Local Contexts cache the Open to Collaborate Notice => #{otc}")
        end
      end
      LocalContextsProject.each_with_index do |lcp, idx|
        if (AppConfig.has_key?(:local_contexts_projects) && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true) || idx != 0
          @job.write_output("Waiting for #{AppConfig[:local_contexts_api_wait_time]} seconds to refresh the next project's cache")
          sleep(AppConfig[:local_contexts_api_wait_time])
        end
        begin
          msg = lcp_client.reset_cache(lcp[:project_id])
          if msg['unique_id'] == lcp[:project_id]
            @job.write_output(" -> Success refreshing Local Contexts cache for project: #{msg['title']}, with id: #{lcp[:project_id]}")
          else
            @job.write_output(" -> Error refreshing Local Contexts cache for project with id: #{lcp[:project_id]} => #{msg}")
          end
        rescue => e
          @job.write_output(" -> Error refreshing Local Contexts cache for project with id: #{lcp[:project_id]} => #{e.message}")
        end
      end
      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end

end