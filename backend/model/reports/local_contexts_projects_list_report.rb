class LocalContextsProjectsListReport < AbstractReport

  register_report

  def fix_row(row)
    row[:record_uri] = File.join(AppConfig[:frontend_proxy_url],
                                 "resolve/readonly?uri=/repositories",
                                 row[:repo_id].to_s,
                                 row[:type].gsub(" ","_") + 's',
                                 row[:id].to_s)

    row[:local_contexts_project_uri] = File.join(AppConfig[:frontend_proxy_url], "resolve/readonly?uri=/local_contexts_projects", row[:lcp_id].to_s)

    row[:type] = row[:type].capitalize

    row.delete(:lcp_id)
    row.delete(:repo_id)
    row.delete(:id)
  end

  def query_string
  "(
    SELECT
      local_contexts_project.project_id,
      local_contexts_project.project_name,
      local_contexts_project.id as lcp_id,
      resource.title as title,
      resource.id as id,
      resource.repo_id as repo_id,
      'resource' AS type
    FROM
      local_contexts_project_rlshp lcpr
    LEFT JOIN
      resource ON resource.id = lcpr.resource_id
    LEFT JOIN
      local_contexts_project on local_contexts_project.id = lcpr.local_contexts_project_id
    WHERE
      lcpr.resource_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_contexts_project.project_id,
      local_contexts_project.project_name,
      local_contexts_project.id as lcp_id,
      accession.title as title,
      accession.id as id,
      accession.repo_id as repo_id,
      'accession' AS type
    FROM
      local_contexts_project_rlshp lcpr
    LEFT JOIN
      accession ON accession.id = lcpr.accession_id
    LEFT JOIN
      local_contexts_project on local_contexts_project.id = lcpr.local_contexts_project_id
    WHERE
      lcpr.accession_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_contexts_project.project_id,
      local_contexts_project.project_name,
      local_contexts_project.id as lcp_id,
      archival_object.title as title,
      archival_object.id as id,
      archival_object.repo_id as repo_id,
      'archival object' AS type
    FROM
      local_contexts_project_rlshp lcpr
    LEFT JOIN
      archival_object ON archival_object.id = archival_object_id
    LEFT JOIN
      local_contexts_project on local_contexts_project.id = lcpr.local_contexts_project_id
    WHERE
      lcpr.archival_object_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_contexts_project.project_id,
      local_contexts_project.project_name,
      local_contexts_project.id as lcp_id,
      digital_object.title as title,
      digital_object.id as id,
      digital_object.repo_id as repo_id,
      'digital object' AS type
    FROM
      local_contexts_project_rlshp lcpr
    LEFT JOIN
      digital_object ON digital_object.id = lcpr.digital_object_id
    LEFT JOIN
      local_contexts_project on local_contexts_project.id = lcpr.local_contexts_project_id
    WHERE
      lcpr.digital_object_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_contexts_project.project_id,
      local_contexts_project.project_name,
      local_contexts_project.id as lcp_id,
      digital_object_component.title as title,
      digital_object_component.id as id,
      digital_object_component.repo_id as repo_id,
      'digital object component' AS type
    FROM
      local_contexts_project_rlshp lcpr
    LEFT JOIN
      digital_object_component ON digital_object_component.id = lcpr.digital_object_component_id
    LEFT JOIN
      local_contexts_project on local_contexts_project.id = lcpr.local_contexts_project_id
    WHERE
      lcpr.digital_object_component_id IS NOT NULL
    ORDER BY
      title
  )
  "
  end

end
