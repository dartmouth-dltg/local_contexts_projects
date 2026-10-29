{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/local_contexts_projects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "display_string" => {"type" => "string", "readonly" => true},
      "project_id" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "project_name" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "project_is_public" => {"type" => "boolean"},
      "project_api_key" => {
        "type" => "string",
      }
    }
  }
}
