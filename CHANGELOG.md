# Changelog

* beta-8
  * About 'method' directive in route.yml
    * You can set just one method and is case-insensitive.
    
  * Deleting 'path_as_regexp' directive from the Routing Options
    * Force using regular expression in 'path' directive will be better way.
   `$` will be appended automatically to the end of value on 'path' directive.