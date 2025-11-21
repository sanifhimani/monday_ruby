import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'monday_ruby',
  description: 'A Ruby client library for the monday.com GraphQL API',
  base: '/monday_ruby/',

  head: [
    [
      'script',
      { async: '', src: 'https://www.googletagmanager.com/gtag/js?id=G-1TWB59K0W2' }
    ],
    [
      'script',
      {},
      `window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-1TWB59K0W2');`
    ]
  ],

  ignoreDeadLinks: false,

  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Tutorial', link: '/tutorial/first-integration' },
      { text: 'Guides', link: '/guides/installation' },
      { text: 'Reference', link: '/reference/client' },
      {
        text: 'v1.1.0',
        items: [
          {
            text: 'Changelog',
            link: 'https://github.com/sanifhimani/monday_ruby/blob/main/CHANGELOG.md'
          },
          {
            text: 'Contributing',
            link: 'https://github.com/sanifhimani/monday_ruby/blob/main/CONTRIBUTING.md'
          },
          {
            text: 'Migration Guide',
            link: '/explanation/migration/v1'
          }
        ]
      }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Tutorial', link: '/tutorial/first-integration' }
        ]
      },
      {
        text: 'How-to Guides',
        collapsed: false,
        items: [
          { text: 'Installation & Setup', link: '/guides/installation' },
          { text: 'Authentication', link: '/guides/authentication' },
          { text: 'First Request', link: '/guides/first-request' },
          {
            text: 'Working with Boards',
            collapsed: true,
            items: [
              { text: 'Create a Board', link: '/guides/boards/create' },
              { text: 'Query Boards', link: '/guides/boards/query' },
              { text: 'Update Board Settings', link: '/guides/boards/update' },
              { text: 'Archive & Delete', link: '/guides/boards/delete' },
              { text: 'Duplicate Boards', link: '/guides/boards/duplicate' }
            ]
          },
          {
            text: 'Working with Items',
            collapsed: true,
            items: [
              { text: 'Create Items', link: '/guides/items/create' },
              { text: 'Query Items', link: '/guides/items/query' },
              { text: 'Update Items', link: '/guides/items/update' },
              { text: 'Manage Subitems', link: '/guides/items/subitems' },
              { text: 'Archive & Delete', link: '/guides/items/delete' }
            ]
          },
          {
            text: 'Working with Columns',
            collapsed: true,
            items: [
              { text: 'Create Columns', link: '/guides/columns/create' },
              { text: 'Update Column Values', link: '/guides/columns/update-values' },
              { text: 'Update Multiple Values', link: '/guides/columns/update-multiple' },
              { text: 'Query Column Values', link: '/guides/columns/query' },
              { text: 'Change Metadata', link: '/guides/columns/metadata' }
            ]
          },
          {
            text: 'Working with Groups',
            collapsed: true,
            items: [
              { text: 'Manage Groups', link: '/guides/groups/manage' },
              { text: 'Items in Groups', link: '/guides/groups/items' }
            ]
          },
          {
            text: 'Working with Folders',
            collapsed: true,
            items: [
              { text: 'Manage Folders', link: '/guides/folders/manage' }
            ]
          },
          {
            text: 'Working with Workspaces',
            collapsed: true,
            items: [
              { text: 'Manage Workspaces', link: '/guides/workspaces/manage' }
            ]
          },
          {
            text: 'Working with Updates',
            collapsed: true,
            items: [
              { text: 'Manage Updates', link: '/guides/updates/manage' }
            ]
          },
          {
            text: 'Working with Files',
            collapsed: true,
            items: [
              { text: 'Add Files to Column', link: '/guides/files/add-to-column' },
              { text: 'Add Files to Update', link: '/guides/files/add-to-update' },
              { text: 'Clear Files Column', link: '/guides/files/clear-column' }
            ]
          },
          {
            text: 'Advanced Topics',
            collapsed: true,
            items: [
              { text: 'Pagination', link: '/guides/advanced/pagination' },
              { text: 'Error Handling', link: '/guides/advanced/errors' },
              { text: 'Rate Limiting', link: '/guides/advanced/rate-limiting' },
              { text: 'Complex Queries', link: '/guides/advanced/complex-queries' },
              { text: 'Batch Operations', link: '/guides/advanced/batch' }
            ]
          },
          {
            text: 'Common Use Cases',
            collapsed: true,
            items: [
              { text: 'Task Management', link: '/guides/use-cases/task-management' },
              { text: 'Project Dashboard', link: '/guides/use-cases/dashboard' },
              { text: 'Data Import', link: '/guides/use-cases/import' }
            ]
          }
        ]
      },
      {
        text: 'API Reference',
        collapsed: false,
        items: [
          {
            text: 'Core Concepts',
            collapsed: false,
            items: [
              { text: 'Client', link: '/reference/client' },
              { text: 'Configuration', link: '/reference/configuration' },
              { text: 'Response', link: '/reference/response' },
              { text: 'Errors', link: '/reference/errors' }
            ]
          },
          {
            text: 'Resources',
            collapsed: true,
            items: [
              { text: 'Account', link: '/reference/resources/account' },
              { text: 'Activity Log', link: '/reference/resources/activity-log' },
              { text: 'Board', link: '/reference/resources/board' },
              { text: 'Board View', link: '/reference/resources/board-view' },
              { text: 'Column', link: '/reference/resources/column' },
              { text: 'Folder', link: '/reference/resources/folder' },
              { text: 'Group', link: '/reference/resources/group' },
              { text: 'Item', link: '/reference/resources/item' },
              { text: 'Subitem', link: '/reference/resources/subitem' },
              { text: 'Update', link: '/reference/resources/update' },
              { text: 'Workspace', link: '/reference/resources/workspace' }
            ]
          }
        ]
      },
      {
        text: 'Explanation',
        collapsed: true,
        items: [
          {
            text: 'Architecture & Design',
            collapsed: true,
            items: [
              { text: 'Architecture Overview', link: '/explanation/architecture' },
              { text: 'Design Decisions', link: '/explanation/design' }
            ]
          },
          {
            text: 'Concepts',
            collapsed: true,
            items: [
              { text: 'GraphQL Basics', link: '/explanation/graphql' },
              { text: 'Pagination Strategies', link: '/explanation/pagination' },
              { text: 'Column Values', link: '/explanation/column-values' }
            ]
          },
          {
            text: 'Best Practices',
            items: [
              { text: 'Error Handling Patterns', link: '/explanation/best-practices/errors' },
              { text: 'Rate Limiting Strategy', link: '/explanation/best-practices/rate-limiting' },
              { text: 'Testing Your Integration', link: '/explanation/best-practices/testing' },
              { text: 'Performance Optimization', link: '/explanation/best-practices/performance' }
            ]
          },
          {
            text: 'Migration',
            items: [
              { text: 'v0.x to v1.x', link: '/explanation/migration/v1' }
            ]
          }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/sanifhimani/monday_ruby' },
      {
        icon: {
          svg: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" id="Rubygems--Streamline-Svg-Logos" height="24" width="24"><desc>Rubygems Streamline Icon: https://streamlinehq.com</desc><path fill="#d34231" d="m7.900525 7.99205 -0.01305 -0.01305 -2.89835 2.898325 7.03695 7.0239 2.89835 -2.885275 4.1386 -4.138625L16.1647 7.979v-0.01305H7.887475l0.01305 0.0261Z" stroke-width="0.25"></path><path fill="#d34231" d="M11.99995 0.25 1.7513425 6.125v11.75L11.99995 23.75l10.248625 -5.875v-11.75L11.99995 0.25Zm8.290275 16.502225L11.99995 21.53055 3.709675 16.752225V7.221675L11.99995 2.4433325 20.290225 7.221675v9.53055Z" stroke-width="0.25"></path></svg>'
        },
        link: 'https://rubygems.org/gems/monday_ruby'
      }
    ],

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/sanifhimani/monday_ruby/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    outline: {
      level: [2, 3],
      label: 'On this page'
    }
  }
})
