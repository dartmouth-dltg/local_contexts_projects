require 'date'
require 'aspace_logger'
class LocalContextsEAD

  def self.include_lcps?(lcps)
    return false if lcps.empty?
    lcps.each do |lcp|
      unless lcp['_resolved']
        id = JSONModel.parse_reference(lcp['ref'])[:id]
        lc_obj = LocalContextsProject.get_or_die(id)
        resolved = URIResolver.resolve_references(LocalContextsProject.to_jsonmodel(lc_obj), [])
        lcp['_resolved'] = resolved.to_hash
      end
      if lcp['_resolved']['project_is_public'] === true
        return true
      end
    end
    return false
  end

  def self.serialize_local_contexts_collaborate(data, xml, fragments, ead_serializer_class)
    if AppConfig[:plugins].include?('local_contexts_projects') && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true
      otc = LocalContextsClient.new.get_data_from_local_contexts_api("open_to_collaborate", 'open_to_collaborate', true)
      ead_serializer_caller = ead_serializer_class.new
      if otc['name']
        xml.note {
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(otc['name'] , xml, fragments)
          }
          xml.p {
            xml.extref ({"xlink:href" => otc['img_url'],
                        "xlink:actuate" => "onLoad",
                        "xlink:show" => "embed",
                        "xlink:type" => "simple"
            })
          }
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(otc['default_text'] , xml, fragments)
          }
        }
      end
    end
  end

  # custom method to include Local Contexts data
  def self.serialize_local_contexts_ead(data, xml, fragments, ead_serializer_class)
    if AppConfig[:plugins].include?('local_contexts_projects')
      current_date = Time.now.strftime("%d/%m/%Y %H:%M")
      ead_serializer_caller = ead_serializer_class.new
      lcps = data.local_contexts_projects
      include_lcps = include_lcps?(lcps)
      if include_lcps
        xml.odd {
          xml.head {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") , xml, fragments)
          }
          construct_lc_intro(lcps, xml, fragments, ead_serializer_caller)

          # loop through each attached id
          data.local_contexts_projects.each do |lcp|
            construct_project_ead(lcp, xml, fragments, ead_serializer_caller)
          end
          }
      end
    end
  end

  def self.serialize_local_contexts_ead_for_digital_objects(digital_object, xml, fragments, ead_serializer_class)
    if AppConfig[:plugins].include?('local_contexts_projects')
      ead_serializer_caller = ead_serializer_class.new
      lcps = digital_object['local_contexts_projects']
      include_lcps = include_lcps?(lcps)
      if include_lcps
        xml.note {
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") + '. ' + I18n.t("local_contexts_project.digital_object_note", :title => digital_object['title']) , xml, fragments)
          }

          construct_lc_intro(lcps, xml, fragments, ead_serializer_caller)

          # loop through each attached id
          lcps.each do |lcp|
            construct_project_ead(lcp, xml, fragments, ead_serializer_caller)
          end
        }
      end
    end
  end

  def self.construct_lc_intro(lcps, xml, fragments, ead_serializer_caller)
    current_date = Time.now.strftime("%B %d, %Y")

    if lcps.length > 1
      xml.p {
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._plural") , xml, fragments)
      }
    else
      xml.p {
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._singular") , xml, fragments)
      }
    end
    xml.p {
      ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_date_information") + current_date + '. ' + I18n.t("local_contexts_project.project_date_see_current"), xml, fragments)
    }
  end

  def self.construct_project_ead(lcp, xml, fragments, ead_serializer_caller)
    lc_labels = ['bc_labels', 'tk_labels']
    unless lcp['_resolved']
      id = JSONModel.parse_reference(lcp['ref'])[:id]
      lc_obj = LocalContextsProject.get_or_die(id)
      resolved = URIResolver.resolve_references(LocalContextsProject.to_jsonmodel(lc_obj), [])
      lcp['_resolved'] = resolved.to_hash
    end
    if lcp['_resolved'] && lcp['_resolved']['project_id'] && lcp['_resolved']['project_is_public'] === true
      project_id = lcp['_resolved']['project_id']
      project_url = File.join(AppConfig[:local_contexts_base_url], 'projects', project_id)
      project_json = LocalContextsClient.new.get_data_from_local_contexts_api(project_id, 'project', true)

      # for each fetched project, render the data
      if project_json['title'] && project_json['title'].length > 0
        xml.p {
          ead_serializer_caller.sanitize_mixed_content(project_json['title'], xml, fragments)
        }
        xml.p {
          xml.extref ({"xlink:href" => project_url,
                      "xlink:actuate" => "onLoad",
                      "xlink:show" => "new",
                      "xlink:type" => "simple"
                      }) { xml.text I18n.t("local_contexts_project.project_link_text") + " (Project ID: " + project_id + ")"}
        }

        # render labels and notices slightly differently
        project_json.each do |k,v|

          # labels
          if lc_labels.include?(k)
            v.each do |label|
              xml.p {
                ead_serializer_caller.sanitize_mixed_content(label['name'] + " (" + label['language'] + ")", xml, fragments)
              }
              xml.p {
                xml.extref ({"xlink:href" => label['img_url'],
                            "xlink:actuate" => "onLoad",
                            "xlink:show" => "embed",
                            "xlink:type" => "simple"
                })
              }
              xml.p {
                ead_serializer_caller.sanitize_mixed_content(label['label_text'], xml, fragments)
              }
              if label['community']
                xml.p {
                  ead_serializer_caller.sanitize_mixed_content("Placed By: " + label['community'], xml, fragments)
                }
              end
              if label['translations'].length > 0
                label['translations'].each do |translation|
                  xml.p {
                    ead_serializer_caller.sanitize_mixed_content(translation['translated_name']  + " (" + translation['language'] + ")", xml, fragments)
                  }
                  xml.p {
                    ead_serializer_caller.sanitize_mixed_content(translation['translated_text'], xml, fragments)
                  }
                end
              end
            end
          # notices
          elsif k == 'notice'
            v.each do |notice|
              xml.p {
                ead_serializer_caller.sanitize_mixed_content(notice['name'], xml, fragments)
              }
              xml.p {
                xml.extref ({"xlink:href" => notice['img_url'],
                            "xlink:actuate" => "onLoad",
                            "xlink:show" => "embed",
                            "xlink:type" => "simple"
                })
              }
              xml.p {
                ead_serializer_caller.sanitize_mixed_content(notice['default_text'], xml, fragments)
              }
            end
          end
        end
      
      # render error message if the project could not be fetched
      else
        constructed_project_url = AppConfig[:local_contexts_base_url] + "projects/project/" + project_id

        xml.p {
          ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.fetch_error.ead_message"), xml, fragments)
        }
        xml.p {
          xml.extref ({"xlink:href" => constructed_project_url,
                      "xlink:actuate" => "onLoad",
                      "xlink:show" => "new",
                      "xlink:type" => "simple"
                      }) { xml.text I18n.t("local_contexts_project.project_link_text") + " (Project ID: " + project_id + ")"}
        }
      end
    # the project is not public
    else
      xml.p {
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_not_public_message"), xml, fragments)
      }
    end
  end

end
