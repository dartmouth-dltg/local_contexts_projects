{
  "local_contexts_projects" => {
    "type" => "array",
    "items" => {
      "type" => "object",
      "subtype" => "ref",
      "properties" => {
        "ref" => {
          "type" => "JSONModel(:local_contexts_project) uri",
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
