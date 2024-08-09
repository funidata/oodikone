pipeline {
  agent { label 'docker' }

  parameters {
    // Same registry account and IAM user as for Harri
    string(name: "AWS_ECR_REGISTRY", defaultValue: '637423527834.dkr.ecr.eu-north-1.amazonaws.com', description: "AWS ECR registry")
    string(name: "AWS_ECR_CREDENTIALS",  defaultValue: 'aws-oodikone-dev.iam.oodikone-jenkins-dev', description: "Jenkins credentials for AWS ECR")
    string(name: "MASTER_DEPLOY_JOB", defaultValue: 'oodikone-dev', description: "Trigger job for main branch deploy")
  }

  environment {
    VERSION = "${env.TAG_NAME ? env.TAG_NAME : env.BUILD_TAG}"

    // a variant of the BUILD_TAG that remains the same for builds of the same branch
    BUILD_TAG_BASE = "${env.BUILD_TAG.replaceAll(/-\d+$/, '').replaceAll(/-PR-\d+$/, "-${env.CHANGE_BRANCH}")}"

    // used as prefix for Docker containers, allowing multiple concurrent builds on the same host
    // must be unique across Jenkins executors on the host, but also useful to identify what build a container belongs to
    // normalize name for docker compose
    COMPOSE_PROJECT_NAME = "${env.BUILD_TAG.replaceAll(/[^-_a-zA-Z0-9]/, '-').toLowerCase()}"

    // does not need to be unique across builds, could even be shared across jobs
    DOCKER_IMAGE_NAMESPACE = "${params.AWS_ECR_REGISTRY ? "${params.AWS_ECR_REGISTRY}/oodikone" : "oodikone-dev"}"
    DOCKER_IMAGE_TAG = "${env.VERSION}"

    PUSH_TO_ECR = "${env.CHANGE_ID ? pullRequest.labels.contains("push-to-ecr") : true}"
    TOSKA_OODIKONE_REPO = "${env.TOSKA_OODIKONE_REPO ? env.TOSKA_OODIKONE_REPO : "https://github.com/UniversityOfHelsinkiCS/oodikone"}"
    TOSKA_SIS_IMPORTER_REPO = "${env.TOSKA_SIS_IMPORTER_REPO ? env.TOSKA_SIS_IMPORTER_REPO : "https://github.com/UniversityOfHelsinkiCS/sis-importer"}"
  }

  options {
    buildDiscarder(logRotator(daysToKeepStr: '30', numToKeepStr: '100'))
    timestamps()
  }

  stages {
    stage("Copy repos") {
      steps {
        sh "env | sort"
        sh "git -C ../oodikone-contrib pull || git clone ${env.TOSKA_OODIKONE_REPO} ../oodikone-contrib"
        sh "git -C ../sis-importer-contrib pull || git clone ${env.TOSKA_SIS_IMPORTER_REPO} ../sis-importer-contrib"
      }
    }

    stage("Docker build images") {
      steps {
        sh "docker-compose build oodikone-backend oodikone-frontend updater-scheduler updater-worker"
        sh "docker-compose build importer-api importer-mankeli importer-db-api"
      }
    }

    stage("Docker push to ECR") {
      when {
        allOf {
          expression { params.AWS_ECR_REGISTRY }
          environment(name: 'PUSH_TO_ECR', value: 'true')
        }
      }

      environment {
        DOCKER_CONFIG = "${env.HOME}/.aws-docker"
      }

      steps {
        withCredentials([
          usernamePassword(
            credentialsId: params.AWS_ECR_CREDENTIALS,
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY',
          )
        ]) {
          sh "docker-compose push oodikone-backend oodikone-frontend updater-scheduler updater-worker"
          sh "docker-compose push importer-api importer-mankeli importer-db-api"
        }
      }
    }

    stage("Deploy oodikone-dev") {
      when {
        allOf {
          branch 'main'
          expression { params.MASTER_DEPLOY_JOB }
        }
      }

      steps {
        // deploy to oodikone-dev
        build job: params.MASTER_DEPLOY_JOB, wait: false, propagate: false, parameters: [
          // docker image tag
          [$class: 'StringParameterValue', name: 'VERSION', value: "${env.VERSION}"],
        ]
      }
    }
  }
}
