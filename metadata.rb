name             'updatable-attributes'
maintainer       'Annih'
maintainer_email 'b.courtois@criteo.com'
license          'Apache-2.0'
description      'Allow definition of attribute based on other attributes and recomputed on update.'
long_description ::IO.read(::File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.2'

supports         'centos'
supports         'redhat'
supports         'windows'

chef_version     '>= 12.16.23'                                               if respond_to? :chef_version
source_url       'https://github.com/annih/chef-updatable-attributes'        if respond_to? :source_url
issues_url       'https://github.com/annih/chef-updatable-attributes/issues' if respond_to? :issues_url
