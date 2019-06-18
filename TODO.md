# TODO

## Things to delete

 * views (just use a sensible default view of just simple types?)
 * make handlers hang from a singleton (and possibly get rid of xml encoding as well)
 * remove app instances?
 * remove route aliases
 * remove links
 * remove collection summary things...
 * FieldResolver?? and that conditional dependency thing...?
 * remove xml handlers for parsing and rendering. (same for url-encoding) -- (which would allow nil-setting things)
 * simplify or change examples? ...maybe get rid of randexp.
 * get rid of doc browser in lieu to OAPI and redoc
 * change naming of resource definition to endpoint definition
 * traits? ... we still use them...
 * NOTE: make sure the types we use only expose the json-schema types...no longer things like Hash/Struct/Symbol ...(that might be good only for coding/implementation, not for documentation)
 * Plugins? ... maybe leave them out for the moment?
 * change errors to be machine readable
 