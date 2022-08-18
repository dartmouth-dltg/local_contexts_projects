require 'date'
require 'aspace_logger'
class LocalContextsEAD

  def self.include_lcps?(lcps)
    lcps_to_use = []
    lcps.each do |lcp|
      unless lcp['_resolved']
        id = JSONModel.parse_reference(lcp['ref'])[:id]
        lc_obj = LocalContextsProject.get_or_die(id)
        resolved = URIResolver.resolve_references(LocalContextsProject.to_jsonmodel(lc_obj), [])
        lcp['_resolved'] = resolved.to_hash
      end
      if lcp['_resolved']['project_is_public'] === true
        lcps_to_use << lcp
      end
    end
    lcps_to_use
  end

  def self.serialize_local_contexts_collaborate(data, xml, fragments, ead_serializer_class, ead_type = 'ead')
    if AppConfig[:plugins].include?('local_contexts_projects') && AppConfig[:local_contexts_projects]['open_to_collaborate'] == true
      otc = LocalContextsClient.new.get_data_from_local_contexts_api("open_to_collaborate", 'open_to_collaborate', true)
      ead_serializer_caller = ead_serializer_class.new
      if otc['name']
        if ead_type == 'ead'
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
        else
          xml.didnote {
            ead_serializer_caller.sanitize_mixed_content(otc['name'] , xml, fragments)
            xml.lb {}
            xml.ptr ({"href" => otc['img_url'],
                      "actuate" => "onload",
                      "show" => "embed"
              })
            xml.lb {}
            ead_serializer_caller.sanitize_mixed_content(otc['default_text'] , xml, fragments)
          }
        end
      end
    end
  end

  # custom method to include Local Contexts data
  def self.serialize_local_contexts_ead(data, xml, fragments, ead_serializer_class, ead_type = 'ead')
    logger = Logger.new($stderr)
    if AppConfig[:plugins].include?('local_contexts_projects')
      current_date = Time.now.strftime("%d/%m/%Y %H:%M")
      ead_serializer_caller = ead_serializer_class.new
      lcps = data.local_contexts_projects
      include_lcps = include_lcps?(lcps)
      if include_lcps.length > 0
        xml.odd {
          xml.head {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") , xml, fragments)
          }
          construct_lc_intro(include_lcps, xml, fragments, ead_serializer_caller, false, ead_type)
        }
        # loop through each attached id
        logger.debug("LCPS: #{lcps}")

        include_lcps.each do |lcp|
          construct_project_ead(lcp, xml, fragments, ead_serializer_caller, false, ead_type)
        end
      end
    end
  end

  def self.serialize_local_contexts_ead_for_digital_objects(digital_object, xml, fragments, ead_serializer_class, ead_type = 'ead')
    if AppConfig[:plugins].include?('local_contexts_projects')
      ead_serializer_caller = ead_serializer_class.new
      lcps = digital_object['local_contexts_projects']
      include_lcps = include_lcps?(lcps)
      note_type = ead_type == 'ead' ? 'note' : 'didnote'
      if include_lcps.length > 0
        xml.send(note_type) {
          if ead_type == 'ead'
            xml.p {
              ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") + '. ' + I18n.t("local_contexts_project.digital_object_note", :title => digital_object['title']) , xml, fragments)
            }
          else
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") + '. ' + I18n.t("local_contexts_project.digital_object_note", :title => digital_object['title']) , xml, fragments)
            xml.lb {}
          end
          construct_lc_intro(include_lcps, xml, fragments, ead_serializer_caller, true, ead_type)

          # loop through each attached project
          include_lcps.each do |lcp|
            construct_project_ead(lcp, xml, fragments, ead_serializer_caller, true, ead_type)
          end
        }
      end
    end
  end

  def self.construct_lc_intro(lcps, xml, fragments, ead_serializer_caller, digital_object, ead_type)
    current_date = Time.now.strftime("%B %d, %Y")

    if lcps.length > 1
      if digital_object && ead_type == 'ead3'
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._plural") , xml, fragments)
      else
        xml.p {
          ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._plural") , xml, fragments)
        }
      end
    else
      if digital_object && ead_type == 'ead3'
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._singular") , xml, fragments)
      else
        xml.p {
          ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_information._singular") , xml, fragments)
        }
      end
    end
    if digital_object && ead_type == 'ead3'
      xml.lb {}
      ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_date_information") + current_date + '. ' + I18n.t("local_contexts_project.project_date_see_current"), xml, fragments)
    else
      xml.p {
        ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_date_information") + current_date + '. ' + I18n.t("local_contexts_project.project_date_see_current"), xml, fragments)
      }
    end
  end

  def self.project_ref(project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
    if ead_type == 'ead'
      xml.extref ({"xlink:href" => project_url,
                  "xlink:actuate" => "onLoad",
                  "xlink:show" => "new",
                  "xlink:type" => "simple"
      }) { xml.text I18n.t("local_contexts_project.project_link_text") + " (Project ID: " + project_id + ")"}
    else
      xml.ref ({"href" => project_url,
                "actuate" => "onload",
                "show" => "new"
      }) { xml.text I18n.t("local_contexts_project.project_link_text") + " (Project ID: " + project_id + ")"}
    end
  end

  def self.image_ref(label_or_notice, xml, fragments, ead_type)
    if ead_type == 'ead'
      xml.extref ({"xlink:href" => label_or_notice['img_url'],
                  "xlink:actuate" => "onLoad",
                  "xlink:show" => "embed",
                  "xlink:type" => "simple"
      })
    else
      xml.ref ({"href" => label_or_notice['img_url'],
                  "actuate" => "onload",
                  "show" => "embed"
      })
    end
  end

  def self.project_contents(label_or_notice, xml, fragments, ead_serializer_caller, digital_object, ead_type)
    if digital_object && ead_type == 'ead3'
      xml.lb {}
      image_ref(label_or_notice, xml, fragments, ead_type)
    else
      xml.p {
        image_ref(label_or_notice, xml, fragments, ead_type)
      }
    end
    if label_or_notice['label_text']
      if digital_object && ead_type == 'ead3'
        xml.lb {}
        ead_serializer_caller.sanitize_mixed_content(label_or_notice['label_text'], xml, fragments)
      else
        xml.p {
          ead_serializer_caller.sanitize_mixed_content(label_or_notice['label_text'], xml, fragments)
        }
      end
    end
    if label_or_notice['default_text']
      if digital_object && ead_type == 'ead3'
        xml.lb {}
        ead_serializer_caller.sanitize_mixed_content(label_or_notice['default_text'], xml, fragments)
      else
        xml.p {
          ead_serializer_caller.sanitize_mixed_content(label_or_notice['default_text'], xml, fragments)
        }
      end
    end
    if label_or_notice['community']
      if digital_object && ead_type == 'ead3'
        xml.lb {}
        ead_serializer_caller.sanitize_mixed_content("Placed By: " + label_or_notice['community'], xml, fragments)
      else
        xml.p {
          ead_serializer_caller.sanitize_mixed_content("Placed By: " + label_or_notice['community'], xml, fragments)
        }
      end
    end
    if label_or_notice['translations'] && label_or_notice['translations'].length > 0
      label_or_notice['translations'].each do |translation|
        if digital_object && ead_type == 'ead3'
          xml.lb {}
          ead_serializer_caller.sanitize_mixed_content(translation['translated_name']  + " (" + translation['language'] + ")", xml, fragments)
          xml.lb {}
            ead_serializer_caller.sanitize_mixed_content(translation['translated_text'], xml, fragments)
        else
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(translation['translated_name']  + " (" + translation['language'] + ")", xml, fragments)
          }
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(translation['translated_text'], xml, fragments)
          }
        end
      end
    end
  end

  def self.construct_project_ead(lcp, xml, fragments, ead_serializer_caller, digital_object, ead_type)
    lc_labels = ['bc_labels', 'tk_labels']
    tag_name = "odd"
    if lcp['_resolved'] && lcp['_resolved']['project_id'] && lcp['_resolved']['project_is_public'] === true
      project_id = lcp['_resolved']['project_id']
      project_url = File.join(AppConfig[:local_contexts_base_url], 'projects', project_id)
      project_json = LocalContextsClient.new.get_data_from_local_contexts_api(project_id, 'project', true)

      # for each fetched project, render the data
      if project_json['title'] && project_json['title'].length > 0
        if digital_object
          if ead_type == 'ead3'
            xml.lb {}
            ead_serializer_caller.sanitize_mixed_content(project_json['title'], xml, fragments)
            xml.lb {}
            project_ref(project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
          else
            xml.p {
              ead_serializer_caller.sanitize_mixed_content(project_json['title'], xml, fragments)
            }
            xml.p {
              project_ref(project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
            }
          end
        else
        xml.odd {
          xml.head {
            ead_serializer_caller.sanitize_mixed_content(project_json['title'], xml, fragments)
          }
          xml.p {
            project_ref(project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
          }
        }
        end
        # render labels and notices slightly differently
        project_json.each do |k,v|
          # labels
          if lc_labels.include?(k)
            v.each do |label|
              unless digital_object
                begin
                  tag_name = AppConfig[:local_contexts_label_ead_tag_map][label['label_type']]
                rescue
                  logger.info("Label Type: #{label['label_type']} not found in AppConfig[:local_contexts_label_ead_tag_map]. Please add a mapping to an EAD/EAD 3 tag.")
                end
              end
              if digital_object
                if ead_type == 'ead3'
                  xml.lb {}
                  ead_serializer_caller.sanitize_mixed_content(label['name'] + " (" + label['language'] + ")", xml, fragments)
                else
                  xml.p {
                    ead_serializer_caller.sanitize_mixed_content(label['name'] + " (" + label['language'] + ")", xml, fragments)
                  }
                end
                project_contents(label, xml, fragments, ead_serializer_caller, digital_object, ead_type)
              else
                xml.send(tag_name) {
                  xml.head {
                    ead_serializer_caller.sanitize_mixed_content(label['name'] + " (" + label['language'] + ")", xml, fragments)
                  }
                  project_contents(label, xml, fragments, ead_serializer_caller, digital_object, ead_type)
                }
              end
            end
          # notices
          elsif k == 'notice'
            v.each do |notice|
              unless digital_object
                begin
                  tag_name = AppConfig[:local_contexts_label_ead_tag_map][notice['notice_type']]
                rescue
                  logger.info("Label Type: #{notice['notice_type']} not found in AppConfig[:local_contexts_label_ead_tag_map]. Please add a mapping to an EAD/EAD 3 tag.")
                end
              end
              if digital_object
                if ead_type == 'ead3'
                  xml.lb {}
                  ead_serializer_caller.sanitize_mixed_content(notice['name'], xml, fragments)
                else
                  xml.p {
                    ead_serializer_caller.sanitize_mixed_content(notice['name'], xml, fragments)
                  }
                end
                project_contents(notice, xml, fragments, ead_serializer_caller, digital_object, ead_type)
              else
                xml.send(tag_name) {
                  xml.head {
                    ead_serializer_caller.sanitize_mixed_content(notice['name'], xml, fragments)
                  }
                  project_contents(notice, xml, fragments, ead_serializer_caller, digital_object, ead_type)
                }

              end
            end
          end
        end

      # render error message if the project could not be fetched
      else
        constructed_project_url = AppConfig[:local_contexts_base_url] + "projects/project/" + project_id
        if digital_object
          if ead_type == 'ead3'
            xml.lb {}
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.fetch_error.ead_message"), xml, fragments)
            xml.lb {}
            project_ref(constructed_project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
          else
            xml.p {
              ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.fetch_error.ead_message"), xml, fragments)
            }
            xml.p {
              project_ref(constructed_project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
            }
          end
        else
          xml.odd {
            xml.p {
              ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.fetch_error.ead_message"), xml, fragments)
            }
            xml.p {
              project_ref(constructed_project_url, project_id, xml, fragments, ead_serializer_caller, ead_type)
            }
          }
        end
      end

    # the project is not public
    else
      if digital_object
        if ead_type == 'ead3'
          xml.lb {}
          ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_not_public_message"), xml, fragments)
        else
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_not_public_message"), xml, fragments)
          }
        end
      else
        xml.odd {
          xml.p {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.project_not_public_message"), xml, fragments)
          }
        }
      end
    end
  end

end
