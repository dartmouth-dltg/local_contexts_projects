# Local Contexts Plugin

An ArchivesSpace plugin that allows staff users to add & display Local Contexts
Labels (TK & BC), Notices (TK & BC), & Local Contexts Institution
Notices (Attribution Incomplete) on resources, accessions, archival objects,
digital objects, and digital object components by linking a Local Contexts Hub
Project to an object via the project id.

Please read the Local Contexts guidelines for using Labels & Notices and contact them for
additional guidance on best practices.
<a href="https://localcontexts.org/labels/traditional-knowledge-labels/">Local Contexts Traditional Knowledge Labels</a>,
<a href="https://localcontexts.org/labels/biocultural-labels/">Local Contexts Biocultural Labels</a>,
<a href="https://localcontexts.org/notices/aboutnotices/">Local Contexts Notices</a>,
<a href="mailto:support@localcontexts.org">support@localcontexts.org</a>.

Please read the Local Contexts guidelines for using Institution Notices and contact them for
additional guidance on best practices.
<a href="https://localcontexts.org/notices/cultural-institution-notices/">Local Contexts</a> or
<a href="mailto:support@localcontexts.org">support@localcontexts.org</a>.

## Getting started

This plugin has been tested with ArchivesSpace versions 3.1.0+.

Unzip the latest release of the plugin to your
ArchivesSpace plugins directory:

     $ cd /path/to/archivesspace/plugins
     $ unzip institution_notices.zip -d institution_notices

Enable the plugin by editing your ArchivesSpace configuration file
(`config/config.rb`):

     AppConfig[:plugins] = ['other_plugin', 'local_context']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

See also:

  https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md

You will need to shut down ArchivesSpace and migrate the database:

     $ cd /path/to/archivesspace
     $ scripts/setup-database.sh

See also:

  https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md

This will create the tables required by the plugin.

## Configuration

This plugin accepts two configuration options. These options 

1. control the visibility of Local Contexts associated projects as facets in the staff application 
1. control the visibility of Local Contexts associated projects as facets in the PUI
1. control the visibility of the Open to Collaborate Notice on the home page
1. sets the Local Contexts base URL

If the base URL is not set in the config, the url is assumed to be `https://localcontextshub.org/`

Set either `staff_faceting` or `public_faceting` to `true` to
enable Local Contexts associated projects facets in that area.

Set `open_to_collaborate` to `true` to display an Open to Collaborate Notice on the homepage.
Please <a href="https://localcontexts.org/notices/cultural-institution-notices/">read more about using the Open to Collaborate Notice</a> at Local Contexts: 

```
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org/"

    AppConfig[:local_contexts_project] = {
      'staff_faceting' => true,
      'public_faceting' => true,
      'open_to_collaborate' => true
    }
```

## Using the Plugin
You must first create new records in ArchivesSpace for each project you want to link to.
In the plugins menu, under the cog by the repo name, there is an additional entry
`Local Contexts Projects`. Click this to view a list of the current projects, edit a project,
or create a new project.

Access to the this area is governed by a new permission defined in the plugin: `manage_local_contexts_project_record`

This new record contains three fields.
```
  Project ID - the id of the project from the Local Contexts Hub (required)
  Project Name - a user supplied name for easy linking (required)
  Hub Project Public or Discoverable? - a boolean which indicates whether the Local Contexts Hub project has a public facing view. Defaults to true and should be checked for public or discoverable projects.
```
Once you have created one or more projects, you can then link one or more to a record type of your choice.

To link a project to an object, this plugin adds a new subrecord to resources, accessions, archival objects, digital objects, and digital object components: Local Contexts Projects.

The subrecord contains one field - a link to a Local Contexts Project as defined above. In view mode,
there is also a button which fetches the data associated with the project id(s) and displays all
BC Labels, TK Labels, Notices, & Institution Notices associated with the project(s).

On the PUI side, the icons for the labels & notices will be appended to the title of the
object. Fuller descriptions of the labels (including translations) will be added to the object
description area.

If an archival object has not been directly associated with a project, but has an ancestor that
has been, the Local Contexts data will also be added to the display with an additional note
indicating where the inheritance comes from.

EAD, EAD3, & PDF exports for the staff & PUI have also been customized. These add a section
which includes a link to the public facing description of the project if the
`Hub Project is Public` field is checked for that project as well as the Local Contexts data for the project
at the time of export.

### Staff PDF Exports Note

PDF Exports on the staff side rely on an updated EAD to PDF stylesheet. Please replace the core file in
```
  ARCHIVESSPACE_BASE_DIRECTORY/stylesheets/as-ead-psd.xsl
```
with the version found in the `stylesheets` directory of this plugin.

See the `samples` directory in the plugin for sample exports and screenshots.

## Notes
The Local Contexts API does not support authentication at this time so LC Hub data for private projects
cannot be displayed in ArchivesSpace. Should the LC API support authentication, the proposed
plan is to authenticate and display the private project data only in the ArchivesSpace staff view.

## Reports
The plugin adds an additional report: Local Contexts List. The report generates a list of all
projects and their associated primary type (resource, accession, archival object, digital object, and
digital object component), respectively.

## Core Overrides

This plugin overrides several methods related to EAD & EAD3 export. If you have modified these or
are using plugins that also modify these methods, you will need to reconcile them. Specifically

```
    EADSerializer::stream
    EADSerializer::serialize_child
    EADSerializer::serialize_digital_object
    EAD3Serializer::stream
    EAD3Serializer::serialize_child
    EAD3Serializer::serialize_digital_object
```    
This plugin also overrides the following views
```
    /public/views/pdf/_resource.html.erb
    /public/views/pdf/_archival_object.html.erb
    /public/views/shared/_record_innards.html.erb
    /public/views/welcome/show.html.erb
```
If you are using other plugins which override the same files, you will need to reconcile
them.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College

Please visit <a href="https://localcontexts.org/">Local Contexts</a> for more information about
Local Contexts Labels, Notices, & Institution Notices.
