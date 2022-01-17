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
      "linked_record" => {
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:accession) uri"},
                       {"type" => "JSONModel(:resource) uri"},
                       {"type" => "JSONModel(:archival_object) uri"},
                       {"type" => "JSONModel(:digital_object) uri"},
                       {"type" => "JSONModel(:digital_object_component) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      }
    }
  }
}
