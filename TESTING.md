# Testing

## Prerequisites

A working ruby installation (2.7+) with [Bundler](https://bundler.io).

## Tools

### Linting

The linting is done using [Cookstyle](https://github.com/chef/cookstyle), a tailored RuboCop configuration for Chef cookbooks.

### Unit testing

The unit testing is done with [ChefSpec](https://github.com/chef/chefspec), an extension of Rspec for Chef cookbooks.
Chefspec compiles your cookbook code and converges the run in memory, without actually executing the changes. The user can write various assertions based on what they expect to have happened during the Chef run. Chefspec is very fast, and quick useful for testing complex logic as you can easily converge a cookbook many times in different ways.

## Testing your code

The CI is basically running `bundle exec rake` which underhood call the linting and unit testing tasks.

If you just want to apply the linter, run `bundle exec rake cookstyle`.
If you just want to launch the unit tests, run `bundle exec rake rspec`.

## Adding tests

When adding a new feature it is strongly recommended to add unit tests for it in the `spec/unit/` directory.

When fixing a bug it is a good practive to add non-regression tests for it in the `spec/regression/` directory.
