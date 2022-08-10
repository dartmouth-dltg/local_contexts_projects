
class LocalContextsProjectsRefreshCacheRunner < JobRunner

  register_for_job_type('local_contexts_projects_refresh_cache_job')

  def run

    begin
      @job.write_output("Refreshing Local Contexts cache for all Project Ids")
      lcp_client = LocalContextsClient.new
      LocalContextsProject.each do |lcp|
        begin
          msg = lcp_client.reset_cache(lcp[:project_id])
          if msg['unique_id'] == lcp[:project_id]
            @job.write_output(" -> Success refreshing Local Contexts cache for project #{msg['title']} with id: #{lcp[:project_id]}")
          else
            @job.write_output(" -> Error refreshing Local Contexts cache for project with id: #{lcp[:project_id]} => #{msg}")
          end
        rescue => e
          @job.write_output(" -> Error refreshing Local Contexts cache for project with id: #{lcp[:project_id]} => #{e.message}")
        end
        @job.write_output("Waiting for #{AppConfig[:local_contexts_api_wait_time]} seconds to refresh the next project's cache")
        sleep(AppConfig[:local_contexts_api_wait_time])
      end
      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end

end