# Local Contexts Plugin

## About

An ArchivesSpace plugin that allows staff users to add & display Local Contexts
Labels (Traditional Knowledge (TK) & Biocultural (BC)), Notices (TK & BC), & Local Contexts Institution
Notices (Attribution Incomplete) on resources, accessions, archival objects,
digital objects, and digital object components by linking a Local Contexts Hub
Project to an object via the project id. The plugin also supports displaying the Open to Collaborate Notice on
the ArchivesSpace PUI homepage.

Please read the Local Contexts guidelines for using Labels & Notices and contact them for
additional guidance on best practices.
- <a href="https://localcontexts.org/labels/traditional-knowledge-labels/">Local Contexts Traditional Knowledge Labels</a>
- <a href="https://localcontexts.org/labels/biocultural-labels/">Local Contexts Biocultural Labels</a>
- <a href="https://localcontexts.org/notices/aboutnotices/">Local Contexts Notices</a>
- Contact: <a href="mailto:support@localcontexts.org">support@localcontexts.org</a>

Please read the Local Contexts guidelines for using Institution Notices and contact them for
additional guidance on best practices.
- <a href="https://localcontexts.org/notices/cultural-institution-notices/">Local Contexts</a>
- Contact: <a href="mailto:support@localcontexts.org">support@localcontexts.org</a>.

## API Links

- Development API: <a href="https://anth-ja77-lc-dev-42d5.uc.r.appspot.com/api/v1/">https://anth-ja77-lc-dev-42d5.uc.r.appspot.com/api/v1/</a>
- Production API: <a href="https://localcontextshub.org/api/v1/">https://localcontextshub.org/api/v1/</a>
- Documentation: <a href="https://github.com/biocodellc/localcontexts_db/wiki/API-Documentation">Local Contexts API Documentation</a>.

## Getting started

This plugin has been tested with ArchivesSpace versions 3.1.0+.

Unzip the latest release of the plugin to your
ArchivesSpace plugins directory:

     $ cd /path/to/archivesspace/plugins
     $ unzip institution_notices.zip -d local_contexts_projects

Enable the plugin by editing your ArchivesSpace configuration file
(`config/config.rb`):

     AppConfig[:plugins] = ['other_plugin', 'local_contexts_projects']

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

This plugin accepts three configuration options. These options 

- control the visibility of Local Contexts associated projects as facets in the staff application 
- control the visibility of Local Contexts associated projects as facets in the PUI
- control the visibility of the Open to Collaborate Notice on the home page
- set the Local Contexts base URL
- controls the automatic replacement of the `as-ead-pdf.xsl` stylsheet with the plugin version

If the base URL is not set in the config, the url is assumed to be `https://localcontextshub.org/`

If `AppConfig[:local_contexts_replace_xsl]` is not set it is assumed to be true and the `as-ead-pdf.xsl`
stylesheet found in `ARCHIVESSPACE_BASE_DIRECTORY/stylesheets` will automatically be moved aside in favor 
of the plugin version. See the [Staff PDF Exports Note](#staff-pdf-exports-note) for more information.

Set either `staff_faceting` or `public_faceting` to `true` to
enable Local Contexts associated projects facets in that area.

Set `open_to_collaborate` to `true` to display an Open to Collaborate Notice on the homepage.
Please <a href="https://localcontexts.org/notices/cultural-institution-notices/">read more about using the 
Open to Collaborate Notice</a> at Local Contexts: 

Default Values
```
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org/"

    AppConfig[:local_contexts_replace_xsl] = true

    AppConfig[:local_contexts_projects] = {
      'staff_faceting' => false,
      'public_faceting' => false,
      'open_to_collaborate' => false
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

To link a project to an object, this plugin adds a new subrecord to resources, accessions, archival objects,
digital objects, and digital object components. The new subrecord is labeled 'Local Contexts Projects'.

The subrecord contains one field - a link to a Local Contexts Project as defined above. In view mode,
there is a button which fetches the data associated with the project id(s) and displays all
BC Labels, TK Labels, Notices, & Institution Notices associated with the project(s).

On the PUI side, the icons for the labels & notices will be appended to the title of the
object. Fuller descriptions of the labels (including translations) will be added to the object
description area.

If an archival object or digital object component has not been directly associated with a project, but has an ancestor that
has been, the Local Contexts data will also be added to the display with an additional note
indicating where the inheritance comes from.

EAD, EAD3, & PDF exports for the staff & PUI have also been customized. These add a section
which includes a link to the public facing description of the project if the
`Hub Project is Public` field is checked for that project as well as the Local Contexts data for the project
at the time of export.

### <a name="staff-pdf-exports-note"></a>Staff PDF Exports Note

PDF Exports on the staff side rely on (and require) an updated EAD to PDF stylesheet. If you have **NOT** set 

```
  AppConfig[:local_contexts_replace_xsl] = false
```

the plugin will move the current version of `as-ead-pdf.xsl` aside (renaming it to `as-ead-pdf-lc-moved-orig.xsl`)
and copy the plugin version into the stylesheet directory

```
  ARCHIVESSPACE_BASE_DIRECTORY/stylesheets
```

If you have already customized this stylesheet, set 

```
  AppConfig[:local_contexts_replace_xsl] = false
```

and then merge and reconcile the changes present in the plugin version of the stylesheet with your 
local customizations. Display of the Local Contexts data must meet certain display requirements (specifically
rendering of images inline) which the plugin stylesheet provides.

See the `samples` directory in the plugin for sample exports and screenshots.

### Caching

The plugin implements a simple caching mechanism to prevent overloading the Local Contexts API. Caching
is turned on for expoorts, but not for on-demand views in the staff UI or PUI. Requests for views in the staff UI
or PUI will update the cache, though.

Cache files are located in a new directory in the ArchivesSpace data directory named `local_contexts_cache`. This
directory is created by the plugin during ArchivesSpace startup if it is not present.

## Notes

The Local Contexts API does not support authentication at this time so LC Hub data for private projects
cannot be displayed in ArchivesSpace. Should the LC API support authentication, the proposed
plan is to authenticate and display the private project data only in the ArchivesSpace staff view.

## Reports

The plugin adds an additional report: Local Contexts List. The report generates a list of all
projects and their associated primary type (resource, accession, archival object, digital objects, 
and digital object components), respectively.

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
    /public/views/pdf/_digital_object_links.html.erb
    /public/views/pdf/_titlepage.html.erb
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
