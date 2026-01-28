/**
 * DDD + Clean Architecture 拡張ルール
 *
 * UseCase層を含むDDDアーキテクチャ向けのルール。
 * 依存方向: routes → usecases → services → repositories
 *
 * 使用方法:
 * .dependency-cruiser.js で以下のようにマージして使用:
 *
 * const baseConfig = require('./.dependency-cruiser.base.js');
 * const dddPreset = require('./presets/ddd.js');
 *
 * module.exports = {
 *   ...baseConfig,
 *   forbidden: [...baseConfig.forbidden, ...dddPreset.forbidden],
 * };
 */

/** @type {import('dependency-cruiser').IForbiddenRuleType[]} */
module.exports = {
  forbidden: [
    // ============================================
    // UseCase層のルール
    // ============================================
    {
      name: 'no-routes-to-services-directly',
      comment: 'routes は services に直接依存せず usecases を経由すること',
      severity: 'warn', // 移行期間は warn
      from: { path: 'src/routes' },
      to: { path: 'src/services' },
    },
    {
      name: 'no-usecases-to-routes',
      comment: 'usecases は routes に依存してはいけない',
      severity: 'error',
      from: { path: 'src/usecases' },
      to: { path: 'src/routes' },
    },
    {
      name: 'no-usecases-to-repositories',
      comment: 'usecases は repositories に直接依存してはいけない',
      severity: 'error',
      from: { path: 'src/usecases' },
      to: { path: 'src/repositories' },
    },
    {
      name: 'no-services-to-usecases',
      comment: 'services は usecases に依存してはいけない',
      severity: 'error',
      from: { path: 'src/services' },
      to: { path: 'src/usecases' },
    },
    {
      name: 'no-repositories-to-usecases',
      comment: 'repositories は usecases に依存してはいけない',
      severity: 'error',
      from: { path: 'src/repositories' },
      to: { path: 'src/usecases' },
    },

    // ============================================
    // Domain層の保護
    // ============================================
    {
      name: 'no-domain-to-infrastructure',
      comment: 'domain は infrastructure に依存してはいけない（DI原則）',
      severity: 'error',
      from: { path: 'src/domain' },
      to: { path: 'src/(repositories|db|llm|external)' },
    },
    {
      name: 'no-domain-to-application',
      comment: 'domain は application層（usecases）に依存してはいけない',
      severity: 'error',
      from: { path: 'src/domain' },
      to: { path: 'src/usecases' },
    },

    // ============================================
    // LLM/外部APIアダプターのルール
    // ============================================
    {
      name: 'no-llm-to-routes',
      comment: 'llm アダプターは routes に依存してはいけない',
      severity: 'error',
      from: { path: 'src/llm' },
      to: { path: 'src/routes' },
    },
    {
      name: 'no-llm-to-usecases',
      comment: 'llm アダプターは usecases に依存してはいけない',
      severity: 'error',
      from: { path: 'src/llm' },
      to: { path: 'src/usecases' },
    },
  ],
};
