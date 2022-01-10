{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "project_id" => {
        "type" => "string",
        "ifmissing" => "error"
      }
    }
  }
}
