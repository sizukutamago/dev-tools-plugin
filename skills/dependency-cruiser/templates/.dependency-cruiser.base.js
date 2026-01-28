/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  extends: 'dependency-cruiser/configs/recommended',
  forbidden: [
    // ============================================
    // Clean Architecture 基本ルール
    // ============================================
    {
      name: 'no-infrastructure-to-services',
      comment: 'repositories/db は services に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(repositories|db)' },
      to: { path: 'src/services' },
    },
    {
      name: 'no-services-to-routes',
      comment: 'services は routes に依存してはいけない',
      severity: 'error',
      from: { path: 'src/services' },
      to: { path: 'src/routes' },
    },
    {
      name: 'no-repositories-to-routes',
      comment: 'repositories は routes に依存してはいけない',
      severity: 'error',
      from: { path: 'src/repositories' },
      to: { path: 'src/routes' },
    },

    // ============================================
    // 循環依存禁止
    // ============================================
    {
      name: 'no-circular',
      comment: '循環依存は禁止',
      severity: 'error',
      from: {},
      to: { circular: true },
    },

    // ============================================
    // 共通ユーティリティのルール
    // ============================================
    {
      name: 'no-utils-to-business-logic',
      comment: 'utils はビジネスロジック層に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(utils|lib|helpers)' },
      to: { path: 'src/(services|routes|repositories)' },
    },

    // ============================================
    // 型定義のルール
    // ============================================
    {
      name: 'no-types-to-implementation',
      comment: 'types は実装に依存してはいけない',
      severity: 'error',
      from: { path: 'src/types' },
      to: { path: 'src/(services|routes|repositories)' },
    },
  ],

  options: {
    doNotFollow: {
      path: 'node_modules',
    },
    tsPreCompilationDeps: true,
    tsConfig: {
      fileName: 'tsconfig.json',
    },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default'],
    },
    reporterOptions: {
      dot: {
        collapsePattern: 'node_modules/(@[^/]+/[^/]+|[^/]+)',
      },
      archi: {
        collapsePattern:
          '^(packages|src|lib|app|test)(/[^/]+)+|node_modules/(@[^/]+/[^/]+|[^/]+)',
      },
    },
  },
};
