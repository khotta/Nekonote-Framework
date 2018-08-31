# Changelog

* beta-8
  * About 'method' directive in route.yml
    * You can set just one method and is case-insensitive.
    
  * Deleting All of the Routing Options
    * Force using regular expression in 'path' directive will be better way. Configuration about whether allow duplocated slash in URL is deleted.
    
  * The change about routing logic
    * `path: /foo` will be converted to `/^foo$/`.
    * `path: /` (for homepage) will be converted to `/^\/?$/`.
    * `path: /path/to/:something` will be converted to `^/path/to/.+$`.