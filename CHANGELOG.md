## v1.1.0 (August 20, 2024)
- Support for working with workspace folders:
  - Query folders
  - Create a folder
  - Update a folder
  - Delete a folder

## v1.0.0 (July 30, 2024)

### Changed

- **Refactor: Flat API replaced by Resource Classes**
  - The client now uses a modular approach with resource classes instead of a flat API.
  - Introduced a `Base` class for resources to encapsulate common functionality.
  - All resource-specific logic is now encapsulated within individual resource classes (e.g., `Account`, `Board`).

### Added

- Support for enums

### Breaking Changes

- **Accessing Resources**:
  - The way resources are accessed has changed.
  - **Old**: `client.account`, `client.create_board`
  - **New**: `client.accounts.query`, `client.board.create`

## v0.6.2 (April 21, 2024)

### Bug Fixes

- Fix formatting args (Issue)[https://github.com/sanifhimani/monday_ruby/issues/18]

## v0.6.1 (March 24, 2024)

### Bug Fixes

- Fix formatting error for single words (Issue)[https://github.com/sanifhimani/monday_ruby/issues/16]

## v0.6.0 (October 9, 2023)

### Added

- Support for working with subitems:
  - Listing subitems
  - Creating a subitem

- Support for working with updates:
  - Create an Update
  - Like an Update
  - Clear an item's updates
  - Delete an update

## v0.5.0 (September 21, 2023)

### Added

- Support for working with board groups:
  - Reading, Creating, Deleting
  - Archiving, Duplicating
  - Moving an item to a group

## v0.4.0 (September 15, 2023)

### Added

- Support for Reading, Creating and Deleting Workspaces

## v0.3.0 (July 10, 2023)

### Added

- Improved error handling
- Support to configure the API version
- Coverage report

## v0.2.0 (July 04, 2023)

### Added

- Support for global config
- VCR for test suite

### Removed

- [BREAKING] Support for Ruby 2.6

## v0.1.0 (June 28, 2023)

- Initial release
