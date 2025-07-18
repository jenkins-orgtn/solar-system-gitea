pipeline {
    agent any

   tools {
        nodejs 'nodejs-24-1-0'
        hudson.plugins.sonar.SonarRunnerInstallation 'SonarQube'
    }
    environment {
        // MONGO_URI = "mongodb+srv://supercluster.d83jj.mongodb.net/superData"
        // MONGO_DB_CREDS = credentials('mongo-db-creds')
        // MONGO_USERNAME = credentials('mongo-db-username')
        // MONGO_PASSWORD = credentials('mongo-db-password')
        SONAR_SCANNER_HOME = tool 'SonarQube';
        SONAR_TOKEN = credentials('sonar-auth-token')
    }

    options {
        disableResume()
        disableConcurrentBuilds abortPrevious: true
    }


    stages{
        stage('Installing Deps') {
            options { timestamps() }
            steps {
                sh 'npm install --no-audit'
            }
        }

        stage('Dependency Scanning') {
            parallel {
                stage('NPM Dep Audit') {
                    steps {
                        sh '''
                            npm audit --audit-level=critical
                            echo $?
                        '''
                    }
                }
                stage('OWASP Dependency Check') {
                    steps {
                        dependencyCheck additionalArguments: '''
                            --scan ./ \
                            --out ./ \
                            --format ALL \
                            --prettyPrint
                        ''', odcInstallation: 'OWASP-depcheck-12'
                        
                    }      
                } 
            }
        }

        stage('Unit test') {
            options { retry(2) }

            steps {
                sh 'echo colon seperated creds: $MONGO_DB_CREDS'
                sh 'echo Mongodb-username: $MONGO_DB_CREDS_USR'
                sh 'echo Mongodb-password: $MONGO_DB_CREDS_PSW'
                sh 'npm test'
            }
        }

        stage('Code Coverage') {

            steps {
                    catchError(buildResult: 'SUCCESS', message: 'Don\'t worry it will be fixed in future releases', stageResult: 'UNSTABLE') {
                        sh 'npm run coverage'
                    }
            }
        }

        stage('SonarQube') {
            steps {
                    sh 'echo $SONAR_SCANNER_HOME '
                    sh '''
                        $SONAR_SCANNER_HOME/bin/sonar-scanner \
                            -Dsonar.projectKey=jenkins-pipeline \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://20.55.48.167:9000 \
                            -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                    '''
                    // waitForQualityGate abortPipeline:true    
            }
        }
        // stage('Install Sonar Scanner') {
        //     steps {
        //         sh 'npm install -g @sonar/scan'
        //     }
        // }

        // stage('SAST - SonarQube Scan') {
        //     steps {
        //         sh '''
        //             npx sonar \
        //               -Dsonar.host.url=http://20.55.48.167:9000 \
        //               -Dsonar.login=$SONAR_TOKEN \
        //               -Dsonar.projectKey=Solar-System-Project
        //         '''
        //     }
        // }
    }

    post {
        always {
            junit allowEmptyResults: true, stdioRetention: 'ALL', testResults: 'dependency-check-junit.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency CheckHTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code-Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'

        }
    }
}

