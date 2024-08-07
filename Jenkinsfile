pipeline {
  agent { label 'docker' }

  parameters {
    // Same registry account and IAM user as for Harri
    string(name: "AWS_ECR_REGISTRY", defaultValue: '637423527834.dkr.ecr.eu-north-1.amazonaws.com', description: "AWS ECR registry")
    string(name: "AWS_ECR_CREDENTIALS",  defaultValue: 'aws-oodikone.iam.oodikone-jenkins-dev', description: "Jenkins credentials for AWS ECR")
  
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

    // used to build only dependent docker image layers
    DOCKER_BUILDKIT = "1"
    PUSH_TO_ECR = "${env.CHANGE_ID ? pullRequest.labels.contains("push-to-ecr") : true}"
    // used for running e2e tests builds if skip-e2e label has not been set
    RUN_E2E_TESTS = "${env.CHANGE_ID ? !pullRequest.labels.contains("skip-e2e") : true}"
  }

  options {
    buildDiscarder(logRotator(daysToKeepStr: '30', numToKeepStr: '100'))
    timestamps()
  }

  stages {
    stage("Setup") {
      environment {
        WORKER_UID = "${env.UID}"
        WORKER_GID = "${env.GID}"
      }

      steps {
        sh "env | sort"

        // Used during the tests and eventually pushed to ECR
        sh "docker-compose build oodikone-backend oodikone-frontend updater-scheduler updater-worker"
        sh "docker-compose build importer-api importer-mankeli importer-db-api"
      }
    }

    // stage("Lint") {
    //   steps {
    //     sh "docker-compose -f tests/docker-compose.yml run --rm --no-deps into-backend flake8"
    //     sh "docker-compose -f tests/docker-compose.yml run --rm --no-deps vapa-backend flake8"
    //   }
    // }

    // stage("Unit test") {
    //   steps {
    //     sh "docker-compose -f tests/docker-compose.yml up into-backend"
    //     sh "docker-compose -f tests/docker-compose.yml up vapa-backend"
    //     sh "docker-compose -f tests/docker-compose.yml up into-frontend"
    //   }

    //   // TODO: some coverage reports?
    //   post {
    //     always {
    //       junit testResults: 'tests/reports/backend/*.xml', checksName: "Backend Unit Tests"
    //       junit testResults: 'tests/reports/frontend/*.xml', checksName: "Frontend Unit Tests"

    //       publishCoverage(
    //         adapters: [
    //           cobertura(
    //             path: 'tests/reports/backend/coverage/*.xml',
    //             thresholds: [
    //               [
    //                 thresholdTarget: 'Line', 
    //                 unhealthyThreshold: 0.7, 
    //                 unstableThreshold: 0.7,
    //                 failUnhealthy: true
    //               ],
    //               [
    //                 thresholdTarget: 'Class', 
    //                 unhealthyThreshold: 0.7, 
    //                 unstableThreshold: 0.7,
    //                 failUnhealthy: true
    //               ]
    //             ]
    //           )
    //         ],
    //         calculateDiffForChangeRequests: true,
    //       )
    //     }

    //     cleanup {
    //       sh "docker-compose -f tests/docker-compose.yml down -v"
    //     }
    //   }
    // }

    // stage("Docker build backends") {
    //   environment {
    //     TARGET_BUILD_STAGE = 'prod'
    //   }

    //   steps {
    //     sh "docker-compose build oodikone-backend oodikone-frontend updater-scheduler updater-worker"
    //     sh "docker-compose build importer-api importer-mankeli importer-db-api"
    //   }
    // }

    // stage("E2E tests") {
    //   when {
    //     environment(name: 'RUN_E2E_TESTS', value: 'true')
    //   }

    //   stages {
    //     stage("E2E - Build test containers") {
    //       environment {
    //         WORKER_UID = "${env.UID}"
    //         WORKER_GID = "${env.GID}"
    //       }

    //       steps {
    //         sh "docker-compose -f tests/robot-compose.yml build"
    //       }
    //     }

    //     stage("E2E test - Firefox") {
    //       environment {
    //         ROBOT_BROWSER = "firefox"
    //       }

    //       steps {
    //         sh "docker-compose -f tests/robot-compose.yml up -d into-backend vapa-backend"
    //         sh "docker-compose -f tests/robot-compose.yml run --rm robot-tests"
    //       }

    //       // TODO: some coverage reports?
    //       post {
    //         always {
    //           junit testResults: "tests/reports/robot/${ROBOT_BROWSER}/junit.xml", checksName: "Firefox E2E Tests"
    //         }

    //         cleanup {
    //           sh "docker-compose -f tests/robot-compose.yml down -v"
    //         }
    //       }
    //     }
    //   }
    // }

    // stage("Docker build remaining prod images") {
    //   environment {
    //     TARGET_BUILD_STAGE = 'prod'
    //   }

    //   steps {
    //     sh "docker-compose build oodikone-backend oodikone-frontend updater-scheduler updater-worker"
    //     sh "docker-compose build importer-api importer-mankeli importer-db-api"
    //   }
    // }

    stage("Docker push to ECR") {
      when {
        expression { params.AWS_ECR_REGISTRY }
        environment(name: 'PUSH_TO_ECR', value: 'true')
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
          branch 'master'
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

//   post {
//     cleanup {
//       sh "docker-compose -f tests/docker-compose.yml down -v"
//       sh "docker-compose -f tests/robot-compose.yml down -v"
//     }
//   }
}
