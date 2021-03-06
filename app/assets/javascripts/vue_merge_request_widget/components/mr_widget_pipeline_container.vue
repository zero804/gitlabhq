<script>
import { isNumber } from 'lodash';
import ArtifactsApp from './artifacts_list_app.vue';
import MrWidgetContainer from './mr_widget_container.vue';
import MrWidgetPipeline from './mr_widget_pipeline.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

/**
 * Renders the pipeline and related deployments from the store.
 *
 * | Props         | Description
 * |---------------|-------------
 * | `mr`          | This is the mr_widget store
 * | `isPostMerge` | If true, show the "post merge" pipeline and deployments
 */
export default {
  name: 'MrWidgetPipelineContainer',
  components: {
    ArtifactsApp,
    Deployment: () => import('./deployment/deployment.vue'),
    MrWidgetContainer,
    MrWidgetPipeline,
    MergeTrainPositionIndicator: () =>
      import('ee_component/vue_merge_request_widget/components/merge_train_position_indicator.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    isPostMerge: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    branch() {
      return this.isPostMerge ? this.mr.targetBranch : this.mr.sourceBranch;
    },
    branchLink() {
      return this.isPostMerge ? this.mr.targetBranch : this.mr.sourceBranchLink;
    },
    deployments() {
      return this.isPostMerge ? this.mr.postMergeDeployments : this.mr.deployments;
    },
    deploymentClass() {
      return this.isPostMerge ? 'js-post-deployment' : 'js-pre-deployment';
    },
    hasDeploymentMetrics() {
      return this.isPostMerge;
    },
    visualReviewAppMeta() {
      return {
        appUrl: this.mr.appUrl,
        mergeRequestId: this.mr.iid,
        sourceProjectId: this.mr.sourceProjectId,
        sourceProjectPath: this.mr.sourceProjectFullPath,
      };
    },
    pipeline() {
      return this.isPostMerge ? this.mr.mergePipeline : this.mr.pipeline;
    },
    showVisualReviewAppLink() {
      return this.mr.visualReviewAppAvailable && this.glFeatures.anonymousVisualReviewFeedback;
    },
    showMergeTrainPositionIndicator() {
      return isNumber(this.mr.mergeTrainIndex);
    },
  },
};
</script>
<template>
  <mr-widget-container>
    <mr-widget-pipeline
      :pipeline="pipeline"
      :pipeline-coverage-delta="mr.pipelineCoverageDelta"
      :builds-with-coverage="mr.buildsWithCoverage"
      :ci-status="mr.ciStatus"
      :has-ci="mr.hasCI"
      :pipeline-must-succeed="mr.onlyAllowMergeIfPipelineSucceeds"
      :source-branch="branch"
      :source-branch-link="branchLink"
      :mr-troubleshooting-docs-path="mr.mrTroubleshootingDocsPath"
      :ci-troubleshooting-docs-path="mr.ciTroubleshootingDocsPath"
    />
    <template #footer>
      <div v-if="mr.exposedArtifactsPath" class="js-exposed-artifacts">
        <artifacts-app :endpoint="mr.exposedArtifactsPath" />
      </div>
      <div v-if="deployments.length" class="mr-widget-extension">
        <deployment
          v-for="deployment in deployments"
          :key="deployment.id"
          :class="deploymentClass"
          :deployment="deployment"
          :show-metrics="hasDeploymentMetrics"
          :show-visual-review-app="showVisualReviewAppLink"
          :visual-review-app-meta="visualReviewAppMeta"
        />
      </div>
      <merge-train-position-indicator
        v-if="showMergeTrainPositionIndicator"
        class="mr-widget-extension"
        :merge-train-index="mr.mergeTrainIndex"
      />
    </template>
  </mr-widget-container>
</template>
