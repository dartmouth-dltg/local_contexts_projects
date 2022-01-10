class LocalContextsListReport < AbstractReport

  register_report

  def query_string
  "(
    SELECT
      local_context.project_id,
      resource.title as title,
      resource.id as id,
      'resource' AS type
    FROM
      local_context
    LEFT JOIN
      resource ON resource.id = local_context.resource_id
    WHERE
      local_context.resource_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_context.project_id,
      accession.title as title,
      accession.id as id,
      'accession' AS type
    FROM
      local_context
    LEFT JOIN
      accession ON accession.id = local_context.accession_id
    WHERE
      local_context.accession_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_context.project_id,
      archival_object.title as title,
      archival_object.id as id,
      'archival object' AS type
    FROM
      local_context
    LEFT JOIN
      archival_object ON archival_object.id = local_context.archival_object_id
    WHERE
      local_context.archival_object_id IS NOT NULL
    ORDER BY
      title
  )
  UNION
  (
    SELECT
      local_context.project_id,
      digital_object.title as title,
      digital_object.id as id,
      'digital object' AS type,
    FROM
      local_context
    LEFT JOIN
      digital_object ON digital_object.id = local_context.digital_object_id
    WHERE
      local_context.digital_object_id IS NOT NULL
    ORDER BY
      title
  )
  "
  end

end
