const {
    restartECSService,
    restartMainDbECSServices,
    restartFeatureFlagsDbECSServices,
    handler
} = require('./index.js')
const {UpdateServiceCommand} = require("@aws-sdk/client-ecs");

const sinon = require('sinon');


describe('restartECSService', () => {
    /**
     * Given a payload containing an ECS service name
     * When `restartECSService()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `ECSClient`
     */
    test('Calls the ECS client with the correct command object', async () => {
        // Given
        const fakeServiceName = 'fake-ecs-service-name';
        const fakeECSClusterName = 'fake-ecs-cluster-name';

        const mockedEnvVar = sinon.stub(process, 'env').value({ECS_CLUSTER_ARN: fakeECSClusterName});
        const ecsClientSpy = {
            send: sinon.stub().resolves({}),
        };

        // When
        await restartECSService(ecsClientSpy, fakeServiceName);

        // Then
        // The `send()` method should only be called once
        expect(ecsClientSpy.send.calledOnce).toBeTruthy()

        // The `UpdateServiceCommand` should have been passed to the call to the `send()` method
        expect(ecsClientSpy.send.calledWith(sinon.match.instanceOf(UpdateServiceCommand))).toBeTruthy();
        const argsCalledWithSpy = ecsClientSpy.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.service).toEqual(fakeServiceName);
        expect(argsCalledWithSpy.cluster).toEqual(fakeECSClusterName);
        expect(argsCalledWithSpy.forceNewDeployment).toBeTruthy();

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('restartMainDbECSServices', () => {
    /**
     * Given environment variables set for the ECS service names
     * When `restartMainDbECSServices()` is called
     * Then the call is delegated to the `restartECSService()`
     *  function for each of the ECS service names
     */
    test('Calls the `restartECSService()` for each ECS service name', async () => {
        // Given
        const fakeCMSAdminECSServiceName = 'fake-cms-admin-ecs-service-name'
        const fakePrivateAPIECSServiceName = 'fake-private-api-ecs-service-name'
        const fakePublicAPIECSServiceName = 'fake-public-api-ecs-service-name'
        const fakeFeedbackAPIECSServiceName = 'fake-feedback-api-ecs-service-name'

        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                CMS_ADMIN_ECS_SERVICE_NAME: fakeCMSAdminECSServiceName,
                PRIVATE_API_ECS_SERVICE_NAME: fakePrivateAPIECSServiceName,
                PUBLIC_API_ECS_SERVICE_NAME: fakePublicAPIECSServiceName,
                FEEDBACK_API_ECS_SERVICE_NAME: fakeFeedbackAPIECSServiceName,
            }
        );

        // Injected dependencies to perform spy operations
        const mockedECSClient = sinon.stub()
        const restartECSServiceSpy = sinon.stub();
        const spyDependencies = {
            restartECSService: restartECSServiceSpy,
        }

        // When
        await restartMainDbECSServices(mockedECSClient, spyDependencies);

        // Then
        // The function should have been called with each ECS service name
        expect(restartECSServiceSpy.firstCall.lastArg).toEqual(fakeCMSAdminECSServiceName)
        expect(restartECSServiceSpy.secondCall.lastArg).toEqual(fakePrivateAPIECSServiceName)
        expect(restartECSServiceSpy.thirdCall.lastArg).toEqual(fakePublicAPIECSServiceName)
        expect(restartECSServiceSpy.lastCall.lastArg).toEqual(fakeFeedbackAPIECSServiceName)

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('restartFeatureFlagsDbECSServices', () => {
    /**
     * Given environment variables set for the ECS service names
     * When `restartFeatureFlagsDbECSServices()` is called
     * Then the call is delegated to the `restartECSService()`
     *  function for each of the ECS service names
     */
    test('Calls the `restartECSService()` for each ECS service name', async () => {
        // Given
        const fakeFeatureFlagsAppECSServiceName = 'fake-feature-flags-ecs-service-name'
        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                FEATURE_FLAGS_ECS_SERVICE_NAME: fakeFeatureFlagsAppECSServiceName,
            }
        );

        // Injected dependencies to perform spy operations
        const mockedECSClient = sinon.stub()
        const restartECSServiceSpy = sinon.stub();
        const spyDependencies = {
            restartECSService: restartECSServiceSpy,
        }

        // When
        await restartFeatureFlagsDbECSServices(mockedECSClient, spyDependencies);

        // Then
        // The function should have been called 3 times, 1 for each ECS service
        expect(restartECSServiceSpy.calledOnce).toBeTruthy();
        // The function should have been called with each ECS service name
        expect(restartECSServiceSpy.firstCall.lastArg).toEqual(fakeFeatureFlagsAppECSServiceName)
        mockedEnvVar.restore();
    });
});


describe('handler', () => {
    /**
     * Given an event object which matches
     *   the `MAIN_DB_PASSWORD_SECRET_ARN` env var
     * When the main `handler()` is called
     * Then the call is delegated to
     *  `restartMainDbECSServices()`
     */
    test('Orchestrates calls correctly for main db secret rotation', async () => {
        // Given
        // Injected dependencies to perform spy operations
        const fakeMatchingSecretARN = 'fake-main-db-secret-arn'
        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                MAIN_DB_PASSWORD_SECRET_ARN: fakeMatchingSecretARN
            }
        );
        const fakeEvent = {"detail": {"additionalEventData": {"SecretId": fakeMatchingSecretARN}}}

        const restartMainDbECSServicesSpy = sinon.stub();
        const restartFeatureFlagsDbECSServicesSpy = sinon.stub();
        const spyDependencies = {
            restartMainDbECSServices: restartMainDbECSServicesSpy,
            restartFeatureFlagsDbECSServices: restartFeatureFlagsDbECSServicesSpy,
        }

        // When
        await handler(fakeEvent, sinon.stub(), spyDependencies)

        // Then
        expect(restartMainDbECSServicesSpy.calledOnce).toBeTruthy();
        expect(restartFeatureFlagsDbECSServicesSpy.notCalled).toBeTruthy();
        mockedEnvVar.restore();
    })

    /**
     * Given an event object which matches
     *   the `FEATURE_FLAGS_DB_PASSWORD_SECRET_ARN` env var
     * When the main `handler()` is called
     * Then the call is delegated to
     *  `restartFeatureFlagsDbECSServices()`
     */
    test('Orchestrates calls correctly for feature flags db secret rotation', async () => {
        // Given
        // Injected dependencies to perform spy operations
        const fakeMatchingSecretARN = 'fake-feature-flags-db-secret-arn'
        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                FEATURE_FLAGS_DB_PASSWORD_SECRET_ARN: fakeMatchingSecretARN
            }
        );
        const fakeEvent = {"detail": {"additionalEventData": {"SecretId": fakeMatchingSecretARN}}}

        const restartMainDbECSServicesSpy = sinon.stub();
        const restartFeatureFlagsDbECSServicesSpy = sinon.stub();
        const spyDependencies = {
            restartMainDbECSServices: restartMainDbECSServicesSpy,
            restartFeatureFlagsDbECSServices: restartFeatureFlagsDbECSServicesSpy,
        }

        // When
        await handler(fakeEvent, sinon.stub(), spyDependencies)

        // Then
        expect(restartMainDbECSServicesSpy.notCalled).toBeTruthy();
        expect(restartFeatureFlagsDbECSServicesSpy.calledOnce).toBeTruthy();
        mockedEnvVar.restore();
    })

})
