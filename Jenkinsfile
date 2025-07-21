pipeline {
    agent any

   tools {
        nodejs 'nodejs-24-1-0'
        // hudson.plugins.sonar.SonarRunnerInstallation 'SonarQube'
    }
    environment {
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-6-10'
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
                            --disableYarnAudit \
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
                timeout(time: 60, unit: 'SECONDS') {
                    withSonarQubeEnv('SonarQube Server') {
                        sh 'echo $SONAR_SCANNER_HOME'
                        sh '''
                            $SONAR_SCANNER_HOME/bin/sonar-scanner \
                                -Dsonar.projectKey=Solar-System-Project \
                                -Dsonar.sources=app.js \
                                -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                        '''
                    }
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build Docker image') {
            steps {
                sh 'printenv'
                sh 'docker build -t samarthdoc123/solar-system:$GIT_COMMIT .'
            }
        }
        stage('Trivy vul scanning') {
            steps{
                sh '''
                    trivy image samarthdoc123/solar-system:$GIT_COMMIT \
                        --severity LOW,MEDIUM \
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-MEDIUM-results.json

                    trivy image samarthdoc123/solar-system:$GIT_COMMIT \
                        --severity CRITICAL \
                        --exit-code 1 \
                        --quiet \
                       --format json -o trivy-image-CRITICAL-results.json
                '''
            }
            post {
                always {
                    sh '''
                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json

                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json

                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                    '''

                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, stdioRetention: 'ALL', testResults: 'dependency-check-junit.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'

            junit allowEmptyResults: true, stdioRetention: 'ALL', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, stdioRetention: 'ALL', testResults: 'trivy-image-CRITICAL-results.xml'
            
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Img Medium vul report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Img Critical vul report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency CheckHTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code-Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

        }
    }
}

