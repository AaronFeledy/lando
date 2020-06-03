'use strict';

// Modules
const _ = require('lodash');
const url = require('url');

/*
 * Helper to normalize routes into arrays
 */
const normalizeRoutes = (routes = {}) => _(routes)
  .map((data, key) => _.merge({}, data, {key}))
  .value();

/*
 * Helper to map redirects to upstreams
 */
const getUpstream = (route, routes) => {
  // If we already have an upstream then WE GOOD!
  if (route.type === 'upstream') return route;
  // If redirect then map to the upstream to which it refers
  else if (route.type === 'redirect') {
    const upstream = _.find(routes, {key: route.to});
    return _.merge({}, route, {type: upstream.type, upstream: upstream.upstream});
  // Otherwise return nothing
  } else {
    return {};
  }
};

/*
 * Helper to map parsed platform config into related Lando things
 */
exports.getLandoProxyRoutes = (routes = {}, supported = []) => _(normalizeRoutes(routes))
  // Map redirects to upstreams
  .map(route => getUpstream(route, normalizeRoutes(routes)))
  // Remove blank entries
  .compact()
  // Parse to lando things
  .map(route => ({
    service: route.upstream.split(':')[0],
    href: url.parse(route.key).hostname,
  }))
  // Filter unsupported upstreams
  .filter(route => _.includes(supported, route.service))
  // Group by service
  .groupBy('service')
  // Map to lando proxy config
  .map((entries, service) => ([service, _.map(entries, 'href')]))
  // objectify
  .fromPairs()
  // Return
  .value();
