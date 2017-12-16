# Cookbook updatable-attributes
[![Cookbook Version][cookbook_version]][cookbook_page]
[![License][license_shield]][license_file]
[![Linux Build Status][linux_build_shield]][linux_build_status]
[![Windows Build Status][windows_build_shield]][windows_build_status]

Expose PCI information via automatic attributes even during compilation time of the first Chef run.

Due to the fact the Ohai plugins system requires a setup phase, this cookbooks does not use it.

## Requirements

This cookbook supports and requires Chef 12.16.23+.

### Platforms

This cookbook leverage built-in Chef features and supports all Platforms.

## Usage

TBD

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
[linux_build_shield]:   https://img.shields.io/travis/Annih/chef-updatable-attributes/master.svg?label=linux
[linux_build_status]:   https://travis-ci.org/Annih/chef-updatable-attributes/branches
[windows_build_shield]: https://img.shields.io/appveyor/ci/Annih/chef-updatable-attributes/master.svg?label=windows
[windows_build_status]: https://ci.appveyor.com/project/Annih/chef-updatable-attributes?branch=master
