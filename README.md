# Local Contexts Plugin

## Note: Beta Status
We're awaiting additional community feedback before creating an official release. Please
use the branch specific to your version of ArchivesSpace
- main => ASpace v3.1.0 & v3.1.1
- as320 => Aspace v3.2.0
- as330 => Aspace v3.3.0 & v3.3.1

## About

An ArchivesSpace plugin that allows staff users to add & display Local Contexts
Labels (Traditional Knowledge (TK) & Biocultural (BC)), Notices (TK, BC, & Attribution Incomplete) 
on resources, accessions, archival objects,
digital objects, and digital object components by linking a Local Contexts Hub
Project to an object via the project id. The plugin also supports displaying the Open to Collaborate Notice on
the ArchivesSpace PUI homepage.

Please read the Local Contexts guidelines for using Labels & Notices and contact them for
additional guidance on best practices.
- <a href="https://localcontexts.org/labels/traditional-knowledge-labels/">Local Contexts Traditional Knowledge Labels</a>
- <a href="https://localcontexts.org/labels/biocultural-labels/">Local Contexts Biocultural Labels</a>
- <a href="https://localcontexts.org/notices/aboutnotices/">Local Contexts Notices</a>
- Contact: <a href="mailto:support@localcontexts.org">support@localcontexts.org</a>

## API Links

- Development API: <a href="https://anth-ja77-lc-dev-42d5.uc.r.appspot.com/api/v1/">https://anth-ja77-lc-dev-42d5.uc.r.appspot.com/api/v1/</a>
- Production API: <a href="https://localcontextshub.org/api/v1/">https://localcontextshub.org/api/v1/</a>
- Documentation: <a href="https://github.com/biocodellc/localcontexts_db/wiki/API-Documentation">Local Contexts API Documentation</a>.

## Getting started

This plugin has been tested with ArchivesSpace versions 3.1.0+.

Unzip the latest relevant release (check for specific releases for specific versions of ArchivesSpace) of the plugin to your
ArchivesSpace plugins directory:

     $ cd /path/to/archivesspace/plugins
     $ unzip local_contexts_projects.zip -d local_contexts_projects

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

This plugin accepts several optional configuration options. These options 

- control the visibility of Local Contexts associated projects as facets in the staff application 
- control the visibility of Local Contexts associated projects as facets in the PUI
- control the visibility of the Open to Collaborate Notice on the home page
- set the Local Contexts base URL
- controls the automatic replacement of the `as-ead-pdf.xsl` stylsheet with the plugin version
- sets the cache time for Open to Collaborate Notice
- sets the cache time for project data
- sets the default time between repeated API calls when refreshing cache for all projects

If the base URL is not set in the config, the url is assumed to be `https://localcontextshub.org/`

If `AppConfig[:local_contexts_replace_xsl]` is not set it is assumed to be true and the `as-ead-pdf.xsl`
stylesheet found in `ARCHIVESSPACE_BASE_DIRECTORY/stylesheets` will automatically be moved aside in favor 
of the plugin version. See the [Staff PDF Exports Note](#staff-pdf-exports-note) for more information.

Set either `staff_faceting` or `public_faceting` to `true` to
enable Local Contexts associated projects facets in that area.

Set `open_to_collaborate` to `true` to display an Open to Collaborate Notice on the homepage.
Please <a href="https://localcontexts.org/notices/cultural-institution-notices/">read more about using the 
Open to Collaborate Notice</a> at Local Contexts. If you choose to display an Open to Collaborate Notice, 
the Notice should also be added to your account in the Local Contexts Hub. 

Default Values
```
    AppConfig[:local_contexts_base_url] = "https://localcontextshub.org/"

    AppConfig[:local_contexts_replace_xsl] = true

    AppConfig[:local_contexts_projects] = {
      'staff_faceting' => false,
      'public_faceting' => false,
      'open_to_collaborate' => false
    }

    AppConfig[:local_contexts_open_to_collaborate_cache_time] = 2592000 # 30 days

    AppConfig[:local_contexts_cache_time] = 604800 # 7 days

    AppConfig[:local_contexts_api_wait_time] = 30
```

## Using the Plugin
You must first create new records in ArchivesSpace for each project you want to link to.
In the plugins menu, under the cog by the repo name, there is an additional entry
`Local Contexts Projects`. Click this to view a list of the current projects, edit a project,
or create a new project.

Access to the this area is governed by a new permission defined in the plugin: `update_localcontexts_project_record`

This new record contains three fields.

- Project ID - the id of the project from the Local Contexts Hub (required)
- Project Name - a user supplied name for easy linking (required)
- Hub Project Public or Discoverable? - a boolean which indicates whether the Local Contexts Hub project has a public facing view. Defaults to true and should be checked for public or discoverable projects.

Once you have created one or more projects, you can then link one or more to a record type of your choice.

To link a project to an object, this plugin adds a new subrecord to resources, accessions, archival objects,
digital objects, and digital object components. The new subrecord is labeled 'Local Contexts Projects'.

The subrecord contains one field - a link to a Local Contexts Project as defined above. In view mode,
there is a button which fetches the data associated with the project id(s) and displays all
BC Labels, TK Labels, & Notices associated with the project(s).

On the PUI side, the icons for the Labels & Notices will be appended to the title of the
object. Fuller descriptions of the Labels (including translations) will be added to the object
description area.

If an archival object or digital object component has not been directly associated with a project, but has an ancestor that
has been, the Local Contexts data will also be added to the display with an additional note
indicating where the inheritance comes from.

## Exports
EAD, EAD3, & PDF exports for the staff & PUI have also been customized. These add a section
which includes a link to the public facing description of the project if the
`Hub Project is Public` field is checked for that project as well as the Local Contexts data for the project
at the time of export.

### Staff EAD/EAD3 Note
The plugin attempts to match Local Contexts Labels and Notices to the most applicable EAD/EAD3 tag. The default
mapping is given below. Note that due to the nature of digital objects data contained in EAD/EAD3 using the `<dao>`
tag, Local Contexts information for linked digital objects is contained within a `<note>` tag instead of using the mapping.

Local Contexts Labels & Notices to EAD/EAD3 Tag Map
```
AppConfig[:local_contexts_label_ead_tag_map] = {
  # Notices
  'traditional_knowledge' => 'userestrict',
  'biocultural' => 'userestrict',
  'attribution_incomplete' => 'custodhist',
  'open_to_collaborate' => 'odd',

  # TK Labels
  'attribution' => 'custodhist',
  'clan' => 'custodhist',
  'family' => 'custodhist',
  'outreach' => 'userestrict',
  'tk_multiple_community' => 'custodhist',
  'non_verified' => 'accessrestrict',
  'verified' => 'accessrestrict',
  'non_commercial' => 'userestrict',
  'commercial' => 'userestrict',
  'culturally_sensitive' => 'accessrestrict',
  'community_voice' => 'custodhist',
  'community_use_only' => 'userestrict',
  'seasonal' => 'accessrestrict',
  'women_general' => 'accessrestrict',
  'men_general' => 'accessrestrict',
  'men_restricted' => 'accessrestrict',
  'women_restricted' => 'accessrestrict',
  'secret_sacred' => 'accessrestrict',
  'open_to_collaboration' => 'userestrict',
  'creative' => 'custodhist',

  # BC Labels
  'provenance' => 'custodhist',
  'commercialization' => 'userestrict',
  'non_commercial' => 'userestrict',
  'collaboration' => 'userestrict',
  'consent_verified' => 'accessrestrict',
  'consent_non_verified' => 'accessrestrict',
  'multiple_community' => 'custodhist',
  'research' => 'userestrict',
  'clan' => 'custodhist',
  'outreach' => 'userestrict'
}
```

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

The plugin implements a simple caching mechanism to decrease render times in the staff interface and PUI
and prevent overloading the Local Contexts API. Cache invalidation is controlled
by the time limits specified by `AppConfig[:local_contexts_cache_time]` and `AppConfig[:local_contexts_open_to_collaborate_cache_time]`
If a request is made to view an object linked to a Local Contexts Project whose cache is out of date, the Local Contexts API is called and the cache for that project is refreshed. Otherwise the cached version of the project data is used for display.

Cache files are located in a new directory in the ArchivesSpace data directory named `local_contexts_cache`. This
directory is created by the plugin during ArchivesSpace startup if it is not present.

Cache files are created at the time of creation of a new Local Contexts Project record and removed on deletion.

For users who can manage Local Contexts Projects, there is an on-demand option to refresh cache data for individual projects 
or for all projects. Cache refresh for all projects is controlled by a new background job. 

A cache check also runs every week (Sunday, 1am) and will refresh any cache that is older than the cache times specified. In practice, this means that the use of the on-demand cache refresh will only be necessary for cases where you know that a project has been updated and you 
need to ensure that the data displayed in ArchivesSpace is up to date.

## Background Job

The plugin adds a new background job `Local Contexts Projects Refresh Cache` which will refresh the cached data for all
Local Contexts Projects. Cache refresh has a delay between API requests to prevent overloading the Local Contexts API. This 
delay is set by `AppConfig[:local_contexts_api_wait_time]` and defaults to 30 seconds between requests.

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
    /public/views/welcome/show.html.erb
```

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College

Please visit <a href="https://localcontexts.org/">Local Contexts</a> for more information about
Local Contexts Labels, & Notices.
