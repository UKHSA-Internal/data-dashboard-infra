const {ECSClient, UpdateServiceCommand} = require("@aws-sdk/client-ecs");

/**
 * Restart the tasks associated with the given ECS service
 *
 * @param {string} serviceName - The name of the ECS service to be restarted.
 * @param {ECSClient} ecsClient - An optional instance of the ECSClient to use for sending the command.
 * @returns {Promise} A promise that resolves once the update service command has been issued.
 */
async function restartECSService(ecsClient = new ECSClient(), serviceName) {
    const input = {
        service: serviceName,
        cluster: process.env.ECS_CLUSTER_ARN,
        forceNewDeployment: true,
    }
    const command = new UpdateServiceCommand(input)
    await ecsClient.send(command)
    console.log(`Restarted all ECS tasks for the '${serviceName}' service`)
}

/**
 * Restarts tasks in all ECS services which depend on the main primary aurora db
 *
 * @param {ECSClient} ecsClient - An optional instance of the ECSClient to use for sending the command.
 * @param {Object} overridenDependencies - Object used to override the default dependencies.
 * @returns {Promise} A promise that resolves once the update service commands have been issued for each ECS service.
 */
async function restartMainDbECSServices(ecsClient = new ECSClient(), overridenDependencies = {}) {
    const defaultDependencies = {restartECSService};
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    await dependencies.restartECSService(ecsClient, process.env.CMS_ADMIN_ECS_SERVICE_NAME)
    await dependencies.restartECSService(ecsClient, process.env.PRIVATE_API_ECS_SERVICE_NAME)
    await dependencies.restartECSService(ecsClient, process.env.PUBLIC_API_ECS_SERVICE_NAME)
    await dependencies.restartECSService(ecsClient, process.env.FEEDBACK_API_ECS_SERVICE_NAME)
    console.log(`All required ECS tasks have been restarted for main DB`);
};


/**
 * Restarts tasks in all ECS services which depend on the feature flags aurora db
 *
 * @param {ECSClient} ecsClient - An optional instance of the ECSClient to use for sending the command.
 * @param {Object} overridenDependencies - Object used to override the default dependencies.
 * @returns {Promise} A promise that resolves once the update service commands have been issued for each ECS service.
 */
async function restartFeatureFlagsDbECSServices(ecsClient = new ECSClient(), overridenDependencies = {}) {
    const defaultDependencies = {restartECSService};
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    await dependencies.restartECSService(ecsClient, process.env.FEATURE_FLAGS_ECS_SERVICE_NAME)
    console.log(`All required ECS tasks have been restarted for feature flags DB`);
};

/**
 * Lambda handler function for restarting client services after an aurora db password has been rotated
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @param {Object} context - The Lambda execution context.
 * @param overridenDependencies - Object used to override the default dependencies.
 */
async function handler(event, context, overridenDependencies = {}) {
    const defaultDependencies = {
        restartMainDbECSServices,
        restartFeatureFlagsDbECSServices,
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    const rotatedSecretARN = event.detail.additionalEventData.SecretId
    if (rotatedSecretARN === process.env.MAIN_DB_PASSWORD_SECRET_ARN) {
        console.log('Restarting main db dependant services')
        await dependencies.restartMainDbECSServices()
    }

    if (rotatedSecretARN === process.env.FEATURE_FLAGS_DB_PASSWORD_SECRET_ARN) {
        console.log('Restarting feature flags db dependant services')
        await dependencies.restartFeatureFlagsDbECSServices()
    }
}

module.exports = {
    handler,
    restartECSService,
    restartMainDbECSServices,
    restartFeatureFlagsDbECSServices,
}