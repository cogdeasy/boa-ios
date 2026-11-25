// Bank of America Mobile Banking iOS - mobile-platform Jenkins (macOS agents)
pipeline {
    agent { label 'macos-xcode' }

    options {
        timeout(time: 45, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
    }

    environment {
        LANG = 'en_US.UTF-8'
        SCHEME = 'BofAMobile-Mock'
        DESTINATION = 'platform=iOS Simulator,name=iPhone 17'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build & Unit Test') {
            steps { sh 'scripts/ci-build.sh' }
        }
        stage('Archive (release branches)') {
            when { branch 'release/*' }
            steps {
                sh '''
                  xcodebuild -project BofAMobile.xcodeproj -scheme BofAMobile \
                    -configuration Release -archivePath build/BofAMobile.xcarchive archive
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build/reports/**', allowEmptyArchive: true
        }
        failure {
            mail to: 'mobile-ios@bofa.com',
                 subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "${env.BUILD_URL}"
        }
    }
}
