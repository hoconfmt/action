# hoconfmt/action

A simple action to reformat hocon files

## inputs

Name|Default|Description
-|-|-
artifact-name | _based on GitHub workflow run_ | name for artifact containing updated files
hocon-files | | space delimited list of file names
hocon-file-list | | path to null delimited list of file names
indentation | 2 | number of spaces to use for each indent step
parallel-tasks | _automatic_ | number of files to format concurrently
suppress-failure | | suppress failure status
suppress-summary | | skip GitHub step summary

While none of the options are individually required, at least one of `hocon-files` or `hocon-file-list` must be specified.

## outputs

### `files`

Contains a list of files that have been modified as well as a `.patch` file.
The patch file is partially a workaround for [actions/upload-artifact#174](https://github.com/actions/upload-artifact/issues/174) and
partially a workaround for the fact that GitHub converts CRLF to LF in step summaries which means you can't use them for patches.

### `id`

Contains a hash of things. The goal is to enable this action to safely run in a matrix. Otherwise, two matrix jobs within a workflow run would generate the same artifact name and the second of those two to try to upload its artifact would fail.
