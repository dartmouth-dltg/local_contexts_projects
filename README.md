# Local Contexts Plugin

An ArchivesSpace plugin that allows staff users to add & display Local Contexts
Labels (TK & BC), Notices (TK & BC), & Local Contexts Institution
Notices (Attribution Incomplete) on resources, accessions, archival objects,
and digital objects. Also provides a configuration option to display Local Contexts
Institution Notices (Open to Collaborate) on the PUI homepage.

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

This will create the tables required by the plugin, and will pre-populate the
system with a set of Institution Notices. The controlled value list is editable
should additional notices be defined in future.

## Configuration

This plugin accepts two configuration options. These options control the visibility of
Local Contexts associated projects as facets in the staff application, control the visibility of Local Contexts associated projects as facets in the PUI, and sets the Local Contexts API base URL. If the API base URL
is not  set in the config, the url is assumed to be `https://localcontextshub.org/api/v1/`

Set either `staff_faceting` or `public_faceting` to `true` to
enable Local Contexts associated projects facets in that area.

```
    AppConfig[:local_context_api_url] = "https://localcontextshub.org/api/v1/"

    AppConfig[:local_context] = {
      'staff_faceting' => true,
      'public_faceting' => true
    }
```

## Stylesheet Changes

To accomodate the use of Local Contexts labels & notices in Staff PDF exports, the ead to pdf stylesheet has
been modified. Please replace your core version in
```
    stylesheets/as-ead-pdf.xsl
```

with the version supplied with the plugin (`local_context/stylesheets/as-ead-pdf.xsl`)

An example EAD to HTML stylesheet based on the one provided in core has also been provided
(`local_context/stylesheets/as-ead-html.xsl`)

## Using the Plugin
This plugin adds a new subrecord to resources, accessions, archival objects, and digital objects:
Institution Notices. The subrecord contains one field - the Local Contexts Project Id. In view mode,
there is a button which fetches the data associated with the project id and displays all
BC Labels, TK Labels, Notices, & Institution Notices associated with the project.

On the PUI side, the icons for the labels & notices will be appended to the title of the
object. Fuller descriptions of the labels (including translations) will be added to the object
description area.

EAD, EAD3, & PDF exports for the staff & PUI have also been customized. These add a note section
which includes a link to the public facing description of the project.

See the `samples` directory in the plugin for sample exports and screenshots.

## Reports
The plugin adds an additional report: Local Contexts List. The report generates a list of all
project ids and their associated primary type (resource, accession, archival object, and
digital object), respectively.

## Core Overrides

This plugin overrides several methods related to EAD & EAD3 export. If you have modified these or
are using plugins that also modify these methods, you will need to reconcile them. Specifically

```
    EADSerializer::stream
    EADSerializer::serialize_child
    EAD3Serializer::stream
    EAD3Serializer::serialize_child
```    
This plugin also overrides the following views
```
    /public/views/pdf/_resource.html.erb
    /public/views/pdf/_archival_object.html.erb
    /public/views/shared/_record_innards.html.erb
    /public/welcome/show.html.erb    
```
If you are using other plugins which override the same files, you will need to reconcile
them.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College

Please visit <a href="https://localcontexts.org/">Local Contexts</a> for more information about
Local Contexts Labels, Notices, & Institution Notices.
