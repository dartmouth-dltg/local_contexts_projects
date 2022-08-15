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

            # Patch for Open to Collaborate Notice
            LocalContextsEAD.serialize_local_contexts_collaborate(data, xml, @fragments, EAD3Serializer)
            # end

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

  # Override this method to include Local Contexts data
  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    file_versions = digital_object['file_versions']
    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end

    atts['linktitle'] = digital_object['title'] if digital_object['title']

    if digital_object['digital_object_type']
      atts['daotype'] = 'otherdaotype'
      atts['otherdaotype'] = digital_object['digital_object_type']
    else
      atts['daotype'] = 'unknown'
    end

    if file_versions.empty?
      atts['href'] = digital_object['digital_object_id']
      atts['actuate'] = 'onrequest'
      atts['show'] = 'new'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.dao(atts) {
        xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      file_versions.each do |file_version|
        atts['href'] = file_version['file_uri'] || digital_object['digital_object_id']
        atts['actuate'] = (file_version['xlink_actuate_attribute'].respond_to?(:downcase) && file_version['xlink_actuate_attribute'].downcase) || 'onrequest'
        atts['show'] = (file_version['xlink_show_attribute'].respond_to?(:downcase) && file_version['xlink_show_attribute'].downcase) || 'new'
        atts['localtype'] = file_version['use_statement'] if file_version['use_statement']
        atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
        xml.dao(atts) {
          xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
        }
      end
    end
    # Local Contexts start
    if digital_object['local_contexts_projects'] && digital_object['local_contexts_projects'].length > 0
      LocalContextsEAD.serialize_local_contexts_ead_for_digital_objects(digital_object, xml, fragments, EAD3Serializer)
    end
    # Local Contexts end}
  end

end
