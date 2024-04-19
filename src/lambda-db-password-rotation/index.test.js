const {
    restartRDSProxy,
    restartECSService,
    restartRequiredECSServices,
    handler
} = require('./index.js')
const {UpdateServiceCommand} = require("@aws-sdk/client-ecs");
const {ModifyDBProxyCommand} = require("@aws-sdk/client-rds");

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


describe('restartRequiredECSServices', () => {
    /**
     * Given environment variables set for the ECS service names
     * When `restartRequiredECSServices()` is called
     * Then the call is delegated to the `restartECSService()`
     *  function for each of the ECS service names
     */
    test('Calls the `restartECSService()` for each ECS service name', async () => {
        // Given
        const fakeCMSAdminECSServiceName = 'fake-cms-admin-ecs-service-name'
        const fakePrivateAPIECSServiceName = 'fake-private-api-ecs-service-name'
        const fakePublicAPIECSServiceName = 'fake-public-api-ecs-service-name'

        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                CMS_ADMIN_ECS_SERVICE_NAME: fakeCMSAdminECSServiceName,
                PRIVATE_API_ECS_SERVICE_NAME: fakePrivateAPIECSServiceName,
                PUBLIC_API_ECS_SERVICE_NAME: fakePublicAPIECSServiceName,
            }
        );

        // Injected dependencies to perform spy operations
        const mockedECSClient = sinon.stub()
        const restartECSServiceSpy = sinon.stub();
        const spyDependencies = {
            restartECSService: restartECSServiceSpy,
        }

        // When
        await restartRequiredECSServices(mockedECSClient, spyDependencies);

        // Then
        // The function should have been called 3 times, 1 for each ECS service
        expect(restartECSServiceSpy.calledThrice).toBeTruthy();
        // The function should have been called with each ECS service name
        expect(restartECSServiceSpy.firstCall.lastArg).toEqual(fakeCMSAdminECSServiceName)
        expect(restartECSServiceSpy.secondCall.lastArg).toEqual(fakePrivateAPIECSServiceName)
        expect(restartECSServiceSpy.thirdCall.lastArg).toEqual(fakePublicAPIECSServiceName)

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('restartRDSProxy', () => {
    /**
     * Given the RDS proxy name and a DB password secret ARN
     * When `restartRDSProxy()` is called
     * Then the correct command is used when
     *  the `send` method is called from the `RDSClient`
     */
    test('Calls the RDS client with the correct command object', async () => {
        // Given
        const fakeRDSProxyName = 'fake-rds-proxy-name';
        const fakeDbPasswordSecretARN = 'fake-db-password-secret-arn';
        const mockedEnvVar = sinon.stub(process, 'env').value(
            {
                RDS_PROXY_NAME: fakeRDSProxyName,
                DB_PASSWORD_SECRET_ARN: fakeDbPasswordSecretARN,
            }
        );
        const rdsClientSpy = {
            send: sinon.stub().resolves({}),
        };

        // When
        await restartRDSProxy(rdsClientSpy);

        // Then
        // The `send()` method should only be called once
        expect(rdsClientSpy.send.calledOnce).toBeTruthy()

        // The `ModifyDBProxyCommand` should have been passed to the call to the `send()` method
        expect(rdsClientSpy.send.calledWith(sinon.match.instanceOf(ModifyDBProxyCommand))).toBeTruthy();
        const argsCalledWithSpy = rdsClientSpy.send.firstCall.args[0].input;
        expect(argsCalledWithSpy.DBProxyName).toEqual(fakeRDSProxyName);
        const expectedAuthPayload = [{SecretArn: fakeDbPasswordSecretARN}]
        expect(argsCalledWithSpy.Auth).toEqual(expectedAuthPayload);

        // Restore the environment variable
        mockedEnvVar.restore();
    });
});


describe('handler', () => {
    /**
     * Given no input
     * When the main `handler()` is called
     * Then the call is delegated to the
     *  `restartRequiredECSServices()`
     *   and `restartRDSProxy()` functions
     */
    test('Orchestrates calls correctly', async () => {
        // Given
        // Injected dependencies to perform spy operations
        const restartRDSProxySpy = sinon.stub();
        const restartRequiredECSServicesSpy = sinon.stub();

        const spyDependencies = {
            restartRDSProxy: restartRDSProxySpy,
            restartRequiredECSServices: restartRequiredECSServicesSpy,
        }

        // When
        await handler(sinon.stub(), sinon.stub(), spyDependencies)

        // Then
        expect(restartRDSProxySpy.calledOnce).toBeTruthy();
        expect(restartRequiredECSServicesSpy.calledOnce).toBeTruthy();
    })

})
