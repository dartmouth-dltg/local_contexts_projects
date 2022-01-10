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

This plugin accepts three configuration options. These options control the visibility of
Institution Notices as facets in the staff application, control the visibility of Institution
Notices as facets in the PUI, and configures the homepage to display the Open to Collaborate Notice
on the PUI homepage. Set either `staff_faceting` or `public_faceting` to `true` to
enable Institution Notices facets in that area. Set `open_to_collaborate` to `true` to enable the
display of the Open to Collaborate Notice on the PUI homepage.

```
    AppConfig[:local_context] = {
      'staff_faceting' => true,
      'public_faceting' => true,
      'open_to_collaborate' => true
    }
```

## Stylesheet Changes

To accomodate the use of Institution Notices in Staff PDF exports, the ead to pdf stylesheet has
been modified. Please replace your core version in
```
    stylesheets/as-ead-pdf.xsl
```

with the version supplied with the plugin (`local_context/stylesheets/as-ead-pdf.xsl`)

An example EAD to HTML stylesheet based on the one provided in core has also been provided
(`local_context/stylesheets/as-ead-html.xsl`)

## Using the Plugin
This plugin adds a new subrecord to resources, accessions, archival objects, and digital objects:
Institution Notices. At this point, there is only one defined Institution Notice available:
Attribution Incomplete.

On the PUI side, if the config option to display the Open to Collaborate Notice has been set, then
the PUI homepage will display the Notice with the associated icon below the search area. If a
resource, accession, archival object, or digital object has an Attribution Incomplete Notice attached,
that notice will be displayed (with icon) below the initial descriptive metadata for that object.

EAD, EAD3, & PDF exports for the staff & PUI have also been customized to include Institution Notices.
These display much like the page view in the PUI.

See the `samples` directory in the plugin for sample exports and screenshots.

## Reports
The plugin adds an additional report: Institution Notices List. The report generates a list of all
Institution Notices and their associated primary type (resource, accession, archival object, and
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
