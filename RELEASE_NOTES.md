## Release Notes

### v2.0.3

* Fix parsing of empty files so they do not halt parsing of all files.
* Update gem dependencies.

#### v2.0.2

* Now prints source name on line with header and footer lines.
* Improve help text.

#### v2.0.1

* Fix license specification in gemspec, update copyright name and year.
* Clarify help text.


#### v2.0.0

* Add features:
  * command line interface
  * support for JSON, Pretty JSON, YAML, AwesomePrint, to_s, and inspect output formats
  * optional array mode (previously only nonarray streaming mode).
  * more persistent options can be specified in an environment variable, `RIKA_OPTIONS`.
  * metadata keys can optionally be sorted alphabetically (not all languages though).
  * properties added by Rika to the metadata: data-source, language
  * Filespec or URL data source identifier can optionally be output with metadata and text.
* Add support for Tika 2.8.0, breaks compatibility with Tika 1.x.
* Remove tika-app-1.24.1.jar from code base and gem (but it is still in git history).
* Tika jar file is now downloaded by the user and found via environment variable `TIKA_JAR_FILESPEC`.
* New class ParseResult created to simplify result access and Parser class.
* Add `Rika.tika_version`.
* Add `webrick` dependency, needed for current versions of Ruby.
* Remove deprecated methods `Parser#available_metadata` and `Parser#metadata_exists?`.
* Move `Parser#language` to `Rika.language`.
* Remove `Parser#language_is_reasonably_certain?`, no longer supported by Tika.
* Remove obsolete `LanguageIdentifier` import. Otherwise updated language detection.
* Various refactorings and improvements.
* Add SimpleCov test coverage and Rubocop linting tools to project.
* Set up RSpec configuration to enable --only-failures and --next-failure options.



#### v1.11.1

* Add Apache-2.0 license to gemspec.


#### v1.11.0

* Replace 2015 Tika jar files w/2020 tika-app-1.24.1.jar.
* Handover of maintainer status from @ricn to @keithrbennett.
* Add rika_helper.rb to provide abbreviated method names for interactive use w/pry, etc.
* Extract parser class to its own file.
* Various cleanup and refactoring.
* Improve README.md documentation.
* Tested successfully on Java 14.
* Move Tika jar file from /target/dependency to /java-lib.
