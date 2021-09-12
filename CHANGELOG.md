# Changelog of the updatable-attributes cookbook

This file is used to list changes made in each version of the updatable-attributes cookbook.

# Version 1.0.2
- Fix UpdateLoop detection system to handle exception raised in subscribers blocks [Issue #5](https://github.com/Annih/chef-updatable-attributes/issues/5)

## Version 1.0.1
- Fix NotificationLoop with Autovivification on Chef <15 [Issue #4](https://github.com/Annih/chef-updatable-attributes/issues/4)

## Version 1.0.0
- Allow control of notification loop & recursion depth
- Pass "previous value" to the subscriber block
- Notify only on actual changes
- Also observe parent attributes changes 

⚠️ **Breaking changes:**

- Setting an attribute to the current value used to notify the subscribers blocks, now only actual changes are notified.
- Attributes update by parent override used to be ignored, now they are notifying the subscribers block if the value changed.

## Version 0.0.2
- Fix calling syntax
- Describe the syntax in the README.md

## Version 0.0.1
- Initial implementation

## Version 0.0.0
- Initial commit
