/**
 * フロントエンド向け依存ルール
 *
 * React/Vue等のフロントエンドプロジェクト向けのルール。
 * 依存方向: pages → components → hooks → utils/lib
 *
 * 使用方法:
 * .dependency-cruiser.js で以下のようにマージして使用:
 *
 * const baseConfig = require('./.dependency-cruiser.base.js');
 * const frontendPreset = require('./presets/frontend.js');
 *
 * module.exports = {
 *   ...baseConfig,
 *   forbidden: [...baseConfig.forbidden, ...frontendPreset.forbidden],
 * };
 */

/** @type {import('dependency-cruiser').IForbiddenRuleType[]} */
module.exports = {
  forbidden: [
    // ============================================
    // Hooks のルール
    // ============================================
    {
      name: 'no-hooks-to-components',
      comment: 'hooks は components に依存してはいけない',
      severity: 'error',
      from: { path: 'src/hooks' },
      to: { path: 'src/components' },
    },
    {
      name: 'no-hooks-to-pages',
      comment: 'hooks は pages に依存してはいけない',
      severity: 'error',
      from: { path: 'src/hooks' },
      to: { path: 'src/(pages|views|screens)' },
    },

    // ============================================
    // Utils/Lib のルール
    // ============================================
    {
      name: 'no-utils-to-components',
      comment: 'utils/lib は components に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(utils|lib|helpers)' },
      to: { path: 'src/components' },
    },
    {
      name: 'no-utils-to-hooks',
      comment: 'utils/lib は hooks に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(utils|lib|helpers)' },
      to: { path: 'src/hooks' },
    },
    {
      name: 'no-utils-to-pages',
      comment: 'utils/lib は pages に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(utils|lib|helpers)' },
      to: { path: 'src/(pages|views|screens)' },
    },

    // ============================================
    // API クライアントのルール
    // ============================================
    {
      name: 'no-api-to-components',
      comment: 'api は components に依存してはいけない',
      severity: 'error',
      from: { path: 'src/api' },
      to: { path: 'src/components' },
    },
    {
      name: 'no-api-to-hooks',
      comment: 'api は hooks に依存してはいけない',
      severity: 'error',
      from: { path: 'src/api' },
      to: { path: 'src/hooks' },
    },
    {
      name: 'no-api-to-pages',
      comment: 'api は pages に依存してはいけない',
      severity: 'error',
      from: { path: 'src/api' },
      to: { path: 'src/(pages|views|screens)' },
    },

    // ============================================
    // Store/State管理のルール
    // ============================================
    {
      name: 'no-store-to-components',
      comment: 'store は components に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(store|stores|state)' },
      to: { path: 'src/components' },
    },
    {
      name: 'no-store-to-pages',
      comment: 'store は pages に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(store|stores|state)' },
      to: { path: 'src/(pages|views|screens)' },
    },

    // ============================================
    // Constants/Config のルール
    // ============================================
    {
      name: 'no-constants-to-ui',
      comment: 'constants は UI層に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(constants|config)' },
      to: { path: 'src/(components|pages|views|screens|hooks)' },
    },

    // ============================================
    // Types のルール
    // ============================================
    {
      name: 'no-types-to-ui',
      comment: 'types は UI実装に依存してはいけない',
      severity: 'error',
      from: { path: 'src/types' },
      to: { path: 'src/(components|pages|views|screens|hooks)' },
    },
  ],
};
