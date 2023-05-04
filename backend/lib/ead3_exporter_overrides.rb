class EAD3Serializer < EADSerializer

  @@AS_VERSION = AppConfig[:lcp_as_version]

  old_stream = instance_method(:stream)
  old_serialize_child = instance_method(:serialize_child)
  old_serialize_digital_object = instance_method(:serialize_digital_object)

  define_method(:stream) do |data|
    case @@AS_VERSION
    when '3.3.x'
      as320_stream(data)
    when '3.2.x'
      as320_stream(data)
    when '3.1.x'
      as310_stream(data)
    end
  end

  define_method(:serialize_child) do |data, xml, fragments, c_depth = 1|
    case @@AS_VERSION
    when '3.3.x'
      as320_serialize_child(data, xml, fragments, c_depth = 1)
    when '3.2.x'
      as320_serialize_child(data, xml, fragments, c_depth = 1)
    when '3.1.x'
      as310_serialize_child(data, xml, fragments, c_depth = 1)
    end
  end

  define_method(:serialize_digital_object) do |digital_object, xml, fragments|
    lcp_serialize_digital_object(digital_object, xml, fragments)
  end

  def as310_stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin
        ead_attributes = {}

        if data.publish === false
          ead_attributes['audience'] = 'internal'
        end

        xml.ead( ead_attributes ) {

          xml.text (
            @stream_handler.buffer { |xml, new_fragments|
              serialize_control(data, xml, new_fragments)
            }
          )

          atts = {:level => data.level, :otherlevel => data.other_level}
          atts.reject! {|k, v| v.nil?}

          xml.archdesc(atts) {

            xml.did {

              unless data.title.nil?
                xml.unittitle { sanitize_mixed_content(data.title, xml, @fragments) }
              end

              xml.unitid (0..3).map { |i| data.send("id_#{i}") }.compact.join('.')

              unless data.repo.nil? || data.repo.name.nil?
                xml.repository {
                  xml.corpname {
                    xml.part {
                      sanitize_mixed_content(data.repo.name, xml, @fragments)
                    }
                  }
                }
              end

              unless (languages = data.lang_materials).empty?
                serialize_languages(languages, xml, @fragments)
              end

              data.instances_with_sub_containers.each do |instance|
                serialize_container(instance, xml, @fragments)
              end

              serialize_extents(data, xml, @fragments)

              serialize_dates(data, xml, @fragments)

              serialize_did_notes(data, xml, @fragments)

              serialize_origination(data, xml, @fragments)

              if @include_unpublished
                data.external_ids.each do |exid|
                  xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
                end
              end

              # change to EAD3Serializer
              EAD3Serializer.run_serialize_step(data, xml, @fragments, :did)

              # Change from EAD 2002: dao must be children of did in EAD3, not archdesc
              data.digital_objects.each do |dob|
                serialize_digital_object(dob, xml, @fragments)
              end

            }# </did>

            serialize_nondid_notes(data, xml, @fragments)

            serialize_bibliographies(data, xml, @fragments)

            serialize_indexes(data, xml, @fragments)

            serialize_controlaccess(data, xml, @fragments)

            # Change to EAD3Serializer
            EAD3Serializer.run_serialize_step(data, xml, @fragments, :archdesc)

            xml.dsc {

              data.children_indexes.each do |i|
                xml.text( @stream_handler.buffer {
                  |xml, new_fragments| serialize_child(data.get_child(i), xml, new_fragments)
                  }
                )
              end
            }
          }
        }

      rescue => e
        xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                  MESSAGE: #{e.message.inspect}  \n
                  TRACE: #{e.backtrace.inspect} \n "
      end
    end

    # Add xml-model for rng
    # Make this conditional if XSD or DTD are requested
    xmlmodel_content = 'href="https://raw.githubusercontent.com/SAA-SDT/EAD3/master/ead3.rng"
      type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'

    xmlmodel = Nokogiri::XML::ProcessingInstruction.new(builder.doc, "xml-model", xmlmodel_content)
    builder.doc.root.add_previous_sibling(xmlmodel)
    builder.doc.root.add_namespace nil, 'http://ead3.archivists.org/schema/'

    Enumerator.new do |y|
      @stream_handler.stream_out(builder, @fragments, y)
    end
  end # END stream

  def as320_stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin
        ead_attributes = {}

        if data.publish === false
          ead_attributes['audience'] = 'internal'
        end

        xml.ead( ead_attributes ) {

          xml.text (
            @stream_handler.buffer { |xml, new_fragments|
              serialize_control(data, xml, new_fragments)
            }
          )

          atts = {:level => data.level, :otherlevel => data.other_level}
          atts.reject! {|k, v| v.nil?}

          xml.archdesc(atts) {

            xml.did {

              unless data.title.nil?
                xml.unittitle { sanitize_mixed_content(data.title, xml, @fragments) }
              end

              xml.unitid (0..3).map { |i| data.send("id_#{i}") }.compact.join('.')

              handle_arks(data, xml)

              unless data.repo.nil? || data.repo.name.nil?
                xml.repository {
                  xml.corpname {
                    xml.part {
                      sanitize_mixed_content(data.repo.name, xml, @fragments)
                    }
                  }
                }
              end

              unless (languages = data.lang_materials).empty?
                serialize_languages(languages, xml, @fragments)
              end

              data.instances_with_sub_containers.each do |instance|
                serialize_container(instance, xml, @fragments)
              end

              serialize_extents(data, xml, @fragments)

              serialize_dates(data, xml, @fragments)

              serialize_did_notes(data, xml, @fragments)

              serialize_origination(data, xml, @fragments)

              if @include_unpublished
                data.external_ids.each do |exid|
                  xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
                end
              end

              EAD3Serializer.run_serialize_step(data, xml, @fragments, :did)

              # Change from EAD 2002: dao must be children of did in EAD3, not archdesc
              data.digital_objects.each do |dob|
                serialize_digital_object(dob, xml, @fragments)
              end

            }# </did>

            serialize_nondid_notes(data, xml, @fragments)

            serialize_bibliographies(data, xml, @fragments)

            serialize_indexes(data, xml, @fragments)

            serialize_controlaccess(data, xml, @fragments)

            EAD3Serializer.run_serialize_step(data, xml, @fragments, :archdesc)

            xml.dsc {

              data.children_indexes.each do |i|
                xml.text( @stream_handler.buffer {
                  |xml, new_fragments| serialize_child(data.get_child(i), xml, new_fragments)
                  }
                )
              end
            }
          }
        }

      rescue => e
        xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                  MESSAGE: #{e.message.inspect}  \n
                  TRACE: #{e.backtrace.inspect} \n "
      end
    end

    # Add xml-model for rng
    # Make this conditional if XSD or DTD are requested
    xmlmodel_content = 'href="https://raw.githubusercontent.com/SAA-SDT/EAD3/master/ead3.rng"
      type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'

    xmlmodel = Nokogiri::XML::ProcessingInstruction.new(builder.doc, "xml-model", xmlmodel_content)
    builder.doc.root.add_previous_sibling(xmlmodel)
    builder.doc.root.add_namespace nil, 'http://ead3.archivists.org/schema/'

    Enumerator.new do |y|
      @stream_handler.stream_out(builder, @fragments, y)
    end
  end # END stream

  def as310_serialize_child(data, xml, fragments, c_depth = 1)
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
        
          # Change to EAD3Serializer
          EAD3Serializer.run_serialize_step(data, xml, fragments, :did)

          data.instances_with_sub_containers.each do |instance|
            serialize_container(instance, xml, @fragments)
          end

          if @include_daos
            data.instances_with_digital_objects.each do |instance|
              serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
            end
          end
        }

        serialize_nondid_notes(data, xml, fragments)
        serialize_bibliographies(data, xml, fragments)
        serialize_indexes(data, xml, fragments)
        serialize_controlaccess(data, xml, fragments)
        # Change to EAD3Serializer
        EAD3Serializer.run_serialize_step(data, xml, fragments, :archdesc)

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

  def as320_serialize_child(data, xml, fragments, c_depth = 1)
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

          handle_arks(data, xml)

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

          EAD3Serializer.run_serialize_step(data, xml, fragments, :did)

          data.instances_with_sub_containers.each do |instance|
            serialize_container(instance, xml, @fragments)
          end

          if @include_daos
            data.instances_with_digital_objects.each do |instance|
              serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
            end
          end
        }

        serialize_nondid_notes(data, xml, fragments)
        serialize_bibliographies(data, xml, fragments)
        serialize_indexes(data, xml, fragments)
        serialize_controlaccess(data, xml, fragments)
        EAD3Serializer.run_serialize_step(data, xml, fragments, :archdesc)

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

  def lcp_serialize_digital_object(digital_object, xml, fragments)
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
    # add run serializer step
    EAD3Serializer.run_serialize_step(digital_object, xml, fragments, :dao)
  end

end