require 'spec_helper'

describe MergeRequestWidgetEntity do
  let(:user) { create(:user) }
  let(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:request) { double('request', current_user: user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  before do
    project.add_developer(user)
  end

  subject do
    described_class.new(merge_request, current_user: user, request: request)
  end

  it 'has blob path data' do
    allow(merge_request).to receive_messages(
      base_pipeline: pipeline,
      head_pipeline: pipeline
    )

    expect(subject.as_json).to include(:blob_path)
    expect(subject.as_json[:blob_path]).to include(:base_path)
    expect(subject.as_json[:blob_path]).to include(:head_path)
  end

  describe 'codeclimate' do
    before do
      allow(merge_request).to receive_messages(
        base_pipeline: pipeline,
        head_pipeline: pipeline
      )
    end

    context 'with codeclimate data' do
      before do
        job = create(:ci_build, pipeline: pipeline)
        create(:ci_job_artifact, :codequality, job: job)
      end

      it 'has codeclimate data entry' do
        expect(subject.as_json).to include(:codeclimate)
      end
    end

    context 'without codeclimate data' do
      it 'does not have codeclimate data entry' do
        expect(subject.as_json).not_to include(:codeclimate)
      end
    end
  end

  it 'sets approvals_before_merge to 0 if nil' do
    expect(subject.as_json[:approvals_before_merge]).to eq(0)
  end

  it 'has performance data' do
    build = create(:ci_build, name: 'job')

    allow(merge_request).to receive_messages(
      expose_performance_data?: true,
      expose_security_dashboard?: false,
      base_performance_artifact: build,
      head_performance_artifact: build
    )

    expect(subject.as_json).to include(:performance)
  end

  it 'has sast data' do
    build = create(:ci_build, name: 'sast', pipeline: pipeline)

    allow(merge_request).to receive_messages(
      expose_sast_data?: true,
      expose_security_dashboard?: true,
      base_has_sast_data?: true,
      base_sast_artifact: build,
      head_sast_artifact: build
    )

    expect(subject.as_json).to include(:sast)
    expect(subject.as_json[:sast]).to include(:head_path)
    expect(subject.as_json[:sast]).to include(:base_path)
  end

  it 'has dependency_scanning data' do
    build = create(:ci_build, name: 'dependency_scanning', pipeline: pipeline)

    allow(merge_request).to receive_messages(
      expose_dependency_scanning_data?: true,
      expose_security_dashboard?: true,
      base_has_dependency_scanning_data?: true,
      base_dependency_scanning_artifact: build,
      head_dependency_scanning_artifact: build
    )

    expect(subject.as_json).to include(:dependency_scanning)
    expect(subject.as_json[:dependency_scanning]).to include(:head_path)
    expect(subject.as_json[:dependency_scanning]).to include(:base_path)
  end

  describe '#license_management' do
    before do
      build = create(:ci_build, name: 'license_management', pipeline: pipeline)

      allow(merge_request).to receive_messages(
        expose_license_management_data?: true,
        expose_security_dashboard?: false,
        base_has_license_management_data?: true,
        base_license_management_artifact: build,
        head_license_management_artifact: build,
        head_pipeline: pipeline,
        target_project: project
      )
    end

    it 'should not be included, if license management features are off' do
      allow(merge_request).to receive_messages(expose_license_management_data?: false)

      expect(subject.as_json).not_to include(:license_management)
    end

    it 'should be included, if license manage management features are on' do
      expect(subject.as_json).to include(:license_management)
      expect(subject.as_json[:license_management]).to include(:head_path)
      expect(subject.as_json[:license_management]).to include(:base_path)
      expect(subject.as_json[:license_management]).to include(:managed_licenses_path)
      expect(subject.as_json[:license_management]).to include(:can_manage_licenses)
      expect(subject.as_json[:license_management]).to include(:license_management_full_report_path)
    end

    it '#license_management_settings_path should not be included for developers' do
      expect(subject.as_json[:license_management]).not_to include(:license_management_settings_path)
    end

    it '#license_management_settings_path should be included for maintainers' do
      stub_licensed_features(license_management: true)
      project.add_maintainer(user)

      expect(subject.as_json[:license_management]).to include(:license_management_settings_path)
    end
  end

  # methods for old artifact are deprecated and replaced with ones for the new name (#5779)
  it 'has sast_container data (with old artifact name gl-sast-container-report.json)' do
    build = create(:ci_build, name: 'container_scanning', pipeline: pipeline)

    allow(merge_request).to receive_messages(
      expose_sast_container_data?: true,
      expose_security_dashboard?: true,
      base_has_sast_container_data?: true,
      base_sast_container_artifact: build,
      head_sast_container_artifact: build
    )

    expect(subject.as_json).to include(:sast_container)
    expect(subject.as_json[:sast_container]).to include(:head_path)
    expect(subject.as_json[:sast_container]).to include(:base_path)
  end

  it 'has sast_container data (with new artifact name gl-container-scanning-report.json)' do
    build = create(:ci_build, name: 'container_scanning', pipeline: pipeline)

    allow(merge_request).to receive_messages(
      expose_container_scanning_data?: true,
      expose_security_dashboard?: true,
      base_has_container_scanning_data?: true,
      base_container_scanning_artifact: build,
      head_container_scanning_artifact: build
    )

    expect(subject.as_json).to include(:sast_container)
    expect(subject.as_json[:sast_container]).to include(:head_path)
    expect(subject.as_json[:sast_container]).to include(:base_path)
  end

  it 'has dast data' do
    build = create(:ci_build, name: 'dast', pipeline: pipeline)

    allow(merge_request).to receive_messages(
      expose_dast_data?: true,
      expose_security_dashboard?: true,
      base_has_dast_data?: true,
      base_dast_artifact: build,
      head_dast_artifact: build
    )

    expect(subject.as_json).to include(:dast)
    expect(subject.as_json[:dast]).to include(:head_path)
    expect(subject.as_json[:dast]).to include(:base_path)
  end

  it 'has vulnerability feedbacks path' do
    expect(subject.as_json).to include(:vulnerability_feedback_path)
  end

  it 'has pipeline id' do
    allow(merge_request).to receive(:head_pipeline).and_return(pipeline)

    expect(subject.as_json).to include(:pipeline_id)
  end
end
