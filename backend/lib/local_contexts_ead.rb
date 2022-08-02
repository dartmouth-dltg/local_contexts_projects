require 'securerandom'
require 'aspace_logger'
require 'date'
class EADSerializer < ASpaceExport::Serializer

  # We're patching this method to deal with the local contexts ids
  # Lot's of copy pasta for one line....sigh

  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      ead_attributes = {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
      }

      if data.publish === false
        ead_attributes['audience'] = 'internal'
      end

      xml.ead( ead_attributes ) {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        atts = {:level => data.level, :otherlevel => data.other_level}
        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {

          xml.did {

            if (val = data.repo.name)
              xml.repository {
                xml.corpname { sanitize_mixed_content(val, xml, @fragments) }
              }
            end

            if (val = data.title)
              xml.unittitle { sanitize_mixed_content(val, xml, @fragments) }
            end

            serialize_origination(data, xml, @fragments)

            xml.unitid (0..3).map {|i| data.send("id_#{i}")}.compact.join('.')

            if @include_unpublished
              data.external_ids.each do |exid|
                xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
              end
            end

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            if (languages = data.lang_materials)
              serialize_languages(languages, xml, @fragments)
            end

            data.instances_with_sub_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

            EADSerializer.run_serialize_step(data, xml, @fragments, :did)

          }# </did>

          # This is it. The patch. All one lines of it
          LocalContextsEAD.serialize_local_contexts_ead(data, xml, @fragments, EADSerializer)
          # end the patch

          data.digital_objects.each do |dob|
            serialize_digital_object(dob, xml, @fragments)
          end

          serialize_nondid_notes(data, xml, @fragments)

          serialize_bibliographies(data, xml, @fragments)

          serialize_indexes(data, xml, @fragments)

          serialize_controlaccess(data, xml, @fragments)

          EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

          xml.dsc {

            data.children_indexes.each do |i|
              xml.text(
                @stream_handler.buffer {|xml, new_fragments|
                  serialize_child(data.get_child(i), xml, new_fragments)
                }
              )
            end
          }
        }
      }
    end
    doc.doc.root.add_namespace nil, 'urn:isbn:1-931666-22-9'

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  end

  def serialize_child(data, xml, fragments, c_depth = 1)
    return if data["publish"] === false && !@include_unpublished
    return if data["suppressed"] === true

    tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

    atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

    if data.publish === false
      atts[:audience] = 'internal'
    end

    atts.reject! {|k, v| v.nil?}
    xml.send(tag_name, atts) {

      xml.did {
        if (val = data.title)
          xml.unittitle { sanitize_mixed_content( val, xml, fragments) }
        end

        if AppConfig[:arks_enabled]
          ark_url = ArkName::get_ark_url(data.id, :archival_object)
          if ark_url
            xml.unitid {
              xml.extref ({"xlink:href" => ark_url,
                           "xlink:actuate" => "onload",
                           "xlink:show" => "new",
                           "xlink:type" => "simple"
                          }) { xml.text 'Archival Resource Key' }
            }
          end
        end

        if !data.component_id.nil? && !data.component_id.empty?
          xml.unitid data.component_id
        end

        if @include_unpublished
          data.external_ids.each do |exid|
            xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
          end
        end

        serialize_origination(data, xml, fragments)
        serialize_extents(data, xml, fragments)
        serialize_dates(data, xml, fragments)
        serialize_did_notes(data, xml, fragments)

        if (languages = data.lang_materials)
          serialize_languages(languages, xml, fragments)
        end

        EADSerializer.run_serialize_step(data, xml, fragments, :did)

        data.instances_with_sub_containers.each do |instance|
          serialize_container(instance, xml, @fragments)
        end

        if @include_daos
          data.instances_with_digital_objects.each do |instance|
            serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
          end
        end
      }

      # This is it. The patch. All one line of it for AOs
      LocalContextsEAD.serialize_local_contexts_ead(data, xml, @fragments, EADSerializer)
      # end the patch

      serialize_nondid_notes(data, xml, fragments)

      serialize_bibliographies(data, xml, fragments)

      serialize_indexes(data, xml, fragments)

      serialize_controlaccess(data, xml, fragments)

      EADSerializer.run_serialize_step(data, xml, fragments, :archdesc)

      data.children_indexes.each do |i|
        xml.text(
          @stream_handler.buffer {|xml, new_fragments|
            serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
          }
        )
      end
    }
  end

end

class EAD3Serializer < EADSerializer
  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      ead_attributes = {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
      }

      if data.publish === false
        ead_attributes['audience'] = 'internal'
      end

      xml.ead( ead_attributes ) {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        atts = {:level => data.level, :otherlevel => data.other_level}
        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {

          xml.did {

            if (val = data.repo.name)
              xml.repository {
                xml.corpname { sanitize_mixed_content(val, xml, @fragments) }
              }
            end

            if (val = data.title)
              xml.unittitle { sanitize_mixed_content(val, xml, @fragments) }
            end

            serialize_origination(data, xml, @fragments)

            xml.unitid (0..3).map {|i| data.send("id_#{i}")}.compact.join('.')

            if @include_unpublished
              data.external_ids.each do |exid|
                xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
              end
            end

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            if (languages = data.lang_materials)
              serialize_languages(languages, xml, @fragments)
            end

            data.instances_with_sub_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

            EADSerializer.run_serialize_step(data, xml, @fragments, :did)

          }# </did>

          # This is it. The patch. All one line of it
          LocalContextsEAD.serialize_local_contexts_ead(data, xml, @fragments, EAD3Serializer)
          # end the patch

          data.digital_objects.each do |dob|
            serialize_digital_object(dob, xml, @fragments)
          end

          serialize_nondid_notes(data, xml, @fragments)

          serialize_bibliographies(data, xml, @fragments)

          serialize_indexes(data, xml, @fragments)

          serialize_controlaccess(data, xml, @fragments)

          EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

          xml.dsc {

            data.children_indexes.each do |i|
              xml.text(
                @stream_handler.buffer {|xml, new_fragments|
                  serialize_child(data.get_child(i), xml, new_fragments)
                }
              )
            end
          }
        }
      }
    end
    doc.doc.root.add_namespace nil, 'urn:isbn:1-931666-22-9'

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  end

  def serialize_child(data, xml, fragments, c_depth = 1)
    begin
      return if data["publish"] === false && !@include_unpublished
      return if data["suppressed"] === true

      tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

      atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

      if data.publish === false
        atts[:audience] = 'internal'
      end

      atts.reject! {|k, v| v.nil?}
      xml.send(tag_name, atts) {

        xml.did {
          if (val = data.title)
            xml.unittitle { sanitize_mixed_content( val, xml, fragments) }
          end

          if AppConfig[:arks_enabled]
            ark_url = ArkName::get_ark_url(data.id, :archival_object)
            if ark_url
              # <unitid><ref href=”ARK” show="new" actuate="onload">ARK</ref></unitid>
              xml.unitid {
                            xml.ref ({"href" => ark_url,
                                      "actuate" => "onload",
                                      "show" => "new"
                                      }) { xml.text 'Archival Resource Key' }
                          }
            end
          end

          if !data.component_id.nil? && !data.component_id.empty?
            xml.unitid data.component_id
          end

          if @include_unpublished
            data.external_ids.each do |exid|
              xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
            end
          end

          serialize_origination(data, xml, fragments)
          serialize_extents(data, xml, fragments)
          serialize_dates(data, xml, fragments)
          serialize_did_notes(data, xml, fragments)

          unless (languages = data.lang_materials).empty?
            serialize_languages(languages, xml, fragments)
          end

          EADSerializer.run_serialize_step(data, xml, fragments, :did)

          data.instances_with_sub_containers.each do |instance|
            serialize_container(instance, xml, @fragments)
          end

          if @include_daos
            data.instances_with_digital_objects.each do |instance|
              serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
            end
          end
        }

        # This is it. The patch. All one line of it for AOs
        LocalContextsEAD.serialize_local_contexts_ead(data, xml, @fragments, EAD3Serializer)
        # end the patch

        serialize_nondid_notes(data, xml, fragments)
        serialize_bibliographies(data, xml, fragments)
        serialize_indexes(data, xml, fragments)
        serialize_controlaccess(data, xml, fragments)
        EADSerializer.run_serialize_step(data, xml, fragments, :archdesc)

        data.children_indexes.each do |i|
          xml.text(
                   @stream_handler.buffer {|xml, new_fragments|
                     serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
                   }
                   )
        end
      }
    rescue => e
      xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF ARCHIVAL OBJECTS. THE FOLLOWING INFORMATION MAY HELP:\n
                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end
  end

end

class LocalContextsEAD

  # custom method to include Local Contexts data
  def self.serialize_local_contexts_ead(data, xml, fragments, ead_serializer_class)
    if AppConfig[:plugins].include?('local_contexts_project')
      lc_labels = ['bc_labels', 'tk_labels']
      current_date = Time.now.strftime("%d/%m/%Y %H:%M")
      ead_serializer_caller = ead_serializer_class.new
      if data.local_contexts_projects && data.local_contexts_projects.length > 0
        xml.odd {
          xml.head {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.section_title") , xml, fragments)
          }
          if data.local_contexts_projects.length > 1
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

          # loop through each attached id
          data.local_contexts_projects.each do |lcp|
            unless lcp['_resolved']
              id = JSONModel.parse_reference(lcp['ref'])[:id]
              lc_obj = LocalContextsProject.get_or_die(id)
              resolved = URIResolver.resolve_references(LocalContextsProject.to_jsonmodel(lc_obj), [])
              lcp['_resolved'] = resolved.to_hash
            end
            if lcp['_resolved'] && lcp['_resolved']['project_id']

              project_id = lcp['_resolved']['project_id']
              project_url = File.join(AppConfig[:local_contexts_base_url], 'projects', project_id)
              project_json = LocalContextsClient.new.get_data_from_local_contexts_api(project_id, 'project')

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
                                    "xlink:actuate" => xlink_load,
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
                xml.p {
                  ead_serializer_caller.sanitize_mixed_content(I18n.t("local_contexts_project.fetch_error.ead_message"), xml, fragments)
                }
                xml.p {
                  xml.extref ({"xlink:href" => project_url,
                              "xlink:actuate" => "onLoad",
                              "xlink:show" => "new",
                              "xlink:type" => "simple"
                              }) { xml.text I18n.t("local_contexts_project.project_link_text") + " (Project ID: " + project_id + ")"}
                }
              end
            end
          end
          }
      end
    end
  end

end
