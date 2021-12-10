# Cookbook updatable-attributes
[![Cookbook Version][cookbook_version]][cookbook_page]
[![License][license_shield]][license_file]
[![CI][ci_shield]][ci_status]

Allow to declare attributes computed each time other ones are updated.

## Requirements

This cookbook supports and requires Chef 12.16.23+.

### Platforms

This cookbook leverage built-in Chef features and supports all Platforms.

## Usage

### To compute attributes based on a single attribute path:

```ruby
on_attribute_update('foo', 'bar') do
  default['blah'] = node['foo']['bar']
end
# equivalent to
on_attribute_update(%w[foo bar]) do
  default['blah'] = node['foo']['bar']
end
```

### To compute attributes based on multiple attribute paths:

```ruby
on_attributes_update(%w[foo bar], 'blah') do
  default['all'] = node['foo']['bar'] + node['blah']
end
# equivalent to
on_attributes_update(%w[foo bar], %w[blah]) do
  default['all'] = node['foo']['bar'] + node['blah']
end
```

### Options

Option                  | Default | Description
------------------------|:-------:|--------------------------------------
*init\_on\_registration*| `true`  | Evaluate the block on registration.
*observe_\parents*      | `true`  | Also observe parent attribute updates.
*recursion*             | `0`     | Configure allowed level of recursion.

### To debug attributes update

Sometimes it is tricky to understand why an attribute ended-up with its final value.
Chef provides the `node.debug_value` method, which is already great, but it only prints the state when you call it.

If you need to debug the "lifecycle" of your attributes, you can enable a temporary debug feature simply using the environment variable: `DEBUG_ATTRIBUTES_KEYS`

The debug feature will evaluate this environment variable as a comma-separated list of attribute's key to watch.
For instance if you want to debug all changes on attributes named "dangerous" *and* "important" you can do this:

```
  DEBUG_ATTRIBUTES_KEYS=dangerous,important sudo -E chef-client
```

As the attributes matching is trivial any attribute key equal to the given values will be logged.
For instance the following attributes changes will be logged:

```
default['dangerous'] = true
default['a']['dangerous']['setting'] = 42
override['not']['important']['at'] = 'all'
```

However the matching is case sensitive on the whole string, so these changes won't be logged:

```
default['almost_dangerous'] = 41
override['very']['Interesting'] = '!'
```

Finally, please note that the default log level used here is `debug`, if you want to change that you should use another environement variable: `DEBUG_ATTRIBUTES_LOG_LEVEL`

For instance to log as warning the use of a dangerous attribute you can do:

```
DEBUG_ATTRIBUTES_LOG_LEVEL=warn DEBUG_ATTRIBUTES_KEYS=dangerous sudo -E chef-client
```
## Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

* Authors [Baptiste Courtois][annih] (<b.courtois@criteo.com>)

```text
Copyright 2017 Baptiste Courtois

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
[annih]:                https://github.com/Annih
[repository]:           https://github.com/Annih/chef-updatable-attributes
[cookbook_version]:     https://img.shields.io/cookbook/v/updatable-attributes.svg
[cookbook_page]:        https://supermarket.chef.io/cookbooks/updatable-attributes
[license_file]:         https://github.com/Annih/chef-updatable-attributes/blob/master/LICENSE
[license_shield]:       https://img.shields.io/github/license/Annih/chef-updatable-attributes.svg
[ci_shield]:            https://github.com/Annih/chef-updatable-attributes/actions/workflows/CI.yml/badge.svg
[ci_status]:            https://github.com/Annih/chef-updatable-attributes/actions/workflows/CI.yml
