# Changelog

* beta-8
  * I'm trying to update Nekonote Framework to be more simpler and slimmed down.

  * The change about `method` directive in route.yml
    * It can be set just one method and is case-insensitive.
    
  * Deleting all of the Routing Options
    * Force using regular expression in `path` directive will be better way. Configuration about whether allow duplocated slash in URL is deleted.
    
  * The change about routing logic
    * `path: /foo` will be converted to `/^\/foo$/`.
    * `path: /` (for homepage) will be converted to `/^\/?$/`.
    * `path: /path/to/:something/foo/:id` will be converted to `/^\/path\/to\/\w+/foo/\w+$/`.
    
  * Deleting `params` directive in route.yml
    * Deleting the methods following `query_string_raw`, `post_data_raw`, `path_params_raw`, `params_raw` in `@request` by this change. Filtering request parameters is not supported.