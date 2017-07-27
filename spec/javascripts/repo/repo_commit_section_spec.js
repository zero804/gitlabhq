import Vue from 'vue';
import repoCommitSection from '~/repo/repo_commit_section.vue';
import RepoStore from '~/repo/repo_store';
import Api from '~/api';

fdescribe('RepoCommitSection', () => {
  const openedFiles = [{
    id: 0,
    changed: true,
    url: 'url0',
    newContent: 'a',
  }, {
    id: 1,
    changed: true,
    url: 'url1',
    newContent: 'b',
  }, {
    id: 2,
    changed: false,
  }];

  function createComponent() {
    const RepoCommitSection = Vue.extend(repoCommitSection);

    return new RepoCommitSection().$mount();
  }

  it('renders a commit section', () => {
    RepoStore.isCommitable = true;
    RepoStore.openedFiles = openedFiles;

    const vm = createComponent();
    const changedFiles = [...vm.$el.querySelectorAll('.changed-files > li')];
    const branchDropdownItems = [...vm.$el.querySelectorAll('.branch-dropdown .dropdown-menu > li')];
    const commitMessage = vm.$el.querySelector('#commit-message');
    const targetBranch = vm.$el.querySelector('#target-branch');
    const newMergeRequest = vm.$el.querySelector('.new-merge-request');
    const newMergeRequestCheckbox = newMergeRequest.querySelector('input');
    const submitCommit = vm.$el.querySelector('.submit-commit');

    expect(vm.$el.querySelector(':scope > form')).toBeTruthy();
    expect(vm.$el.querySelector('.staged-files').textContent).toEqual('Staged files (2)');
    expect(changedFiles.length).toEqual(2);

    changedFiles.forEach((changedFile, i) => {
      expect(changedFile.textContent).toEqual(openedFiles[i].url);
    });

    expect(commitMessage.tagName).toEqual('TEXTAREA');
    expect(commitMessage.name).toEqual('commit-message');
    expect(branchDropdownItems[0].textContent).toEqual('Target branch');
    expect(branchDropdownItems[1].textContent).toEqual('Create my own branch');
    expect(targetBranch.tagName).toEqual('INPUT');
    expect(targetBranch.name).toEqual('target-branch');
    expect(targetBranch.type).toEqual('text');
    expect(newMergeRequest.textContent).toMatch('Start a new merge request with these changes');
    expect(newMergeRequestCheckbox.type).toEqual('checkbox');
    expect(newMergeRequestCheckbox.id).toEqual('checkboxes-0');
    expect(newMergeRequestCheckbox.name).toEqual('checkboxes');
    expect(newMergeRequestCheckbox.value).toEqual('1');
    expect(newMergeRequestCheckbox.checked).toBeFalsy();
    expect(submitCommit.type).toEqual('submit');
    expect(submitCommit.disabled).toBeTruthy();
    expect(vm.$el.querySelector('.commit-summary').textContent).toEqual('Commit 2 Files');
  });

  it('does not render if not isCommitable', () => {
    RepoStore.isCommitable = false;
    RepoStore.openedFiles = [{
      id: 0,
      changed: true,
    }];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  it('does not render if no changedFiles', () => {
    RepoStore.isCommitable = true;
    RepoStore.openedFiles = [];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  it('shows commit submit and summary if commitMessage and spinner if submitCommitsLoading', (done) => {
    const projectId = 'projectId';
    const commitMessage = 'commitMessage';
    RepoStore.isCommitable = true;
    RepoStore.openedFiles = openedFiles;
    RepoStore.projectId = projectId;

    const vm = createComponent();
    const commitMessageEl = vm.$el.querySelector('#commit-message');
    const submitCommit = vm.$el.querySelector('.submit-commit');

    vm.commitMessage = commitMessage;

    Vue.nextTick(() => {
      expect(commitMessageEl.value).toBe(commitMessage);
      expect(submitCommit.disabled).toBeFalsy();

      spyOn(vm, 'makeCommit').and.callThrough();
      spyOn(Api, 'commitMultiple');

      submitCommit.click();

      Vue.nextTick(() => {
        expect(vm.makeCommit).toHaveBeenCalled();
        expect(submitCommit.querySelector('.fa-spinner.fa-spin')).toBeTruthy();

        const args = Api.commitMultiple.calls.allArgs()[0];
        const { commit_message, actions } = args[1];

        expect(args[0]).toBe(projectId);
        expect(commit_message).toBe(commitMessage);
        expect(actions.length).toEqual(2);
        expect(actions[0].action).toEqual('update');
        expect(actions[1].action).toEqual('update');
        expect(actions[0].content).toEqual('a');
        expect(actions[1].content).toEqual('b');

        done();
      });
    });
  });
});
