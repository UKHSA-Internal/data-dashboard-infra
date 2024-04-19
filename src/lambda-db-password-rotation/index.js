const {ECSClient, UpdateServiceCommand} = require("@aws-sdk/client-ecs");
const {RDSClient, ModifyDBProxyCommand} = require("@aws-sdk/client-rds");

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
 * Restarts tasks in all ECS services which depend on the RDS instance
 *
 * @param {ECSClient} ecsClient - An optional instance of the ECSClient to use for sending the command.
 * @param {Object} overridenDependencies - Object used to override the default dependencies.
 * @returns {Promise} A promise that resolves once the update service commands have been issued for each ECS service.
 */
async function restartRequiredECSServices(ecsClient = new ECSClient(), overridenDependencies = {}) {
    const defaultDependencies = {restartECSService};
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    await dependencies.restartECSService(ecsClient, process.env.CMS_ADMIN_ECS_SERVICE_NAME)
    await dependencies.restartECSService(ecsClient, process.env.PRIVATE_API_ECS_SERVICE_NAME)
    await dependencies.restartECSService(ecsClient, process.env.PUBLIC_API_ECS_SERVICE_NAME)
    console.log(`All required ECS tasks have been restarted`);
};

/**
 * Restart the RDS proxy associated with the main RDS instance
 *
 * @param {RDSClient} rdsClient - An optional instance of the RDSClient to use for sending the command.
 * @returns {Promise} A promise that resolves once the modify db proxy command has been issued.
 */
async function restartRDSProxy(rdsClient = new RDSClient()) {
    const input = {
        DBProxyName: process.env.RDS_PROXY_NAME,
        Auth: [{SecretArn: process.env.DB_PASSWORD_SECRET_ARN}],
    }
    const command = new ModifyDBProxyCommand(input);
    await rdsClient.send(command);

    console.log(`Restarted '${process.env.RDS_PROXY_NAME}'`)
};

/**
 * Lambda handler function for restarting client services after the main RDS password has been rotated
 *
 * @param {Object} event - The event object triggered by the Lambda invocation.
 * @param {Object} context - The Lambda execution context.
 * @param overridenDependencies - Object used to override the default dependencies.
 */
async function handler(event, context, overridenDependencies = {}) {
    const defaultDependencies = {
        restartRDSProxy,
        restartRequiredECSServices,
    };
    const dependencies = {...defaultDependencies, ...overridenDependencies};

    await dependencies.restartRequiredECSServices()
    await dependencies.restartRDSProxy()
}

module.exports = {
    handler,
    restartRDSProxy,
    restartECSService,
    restartRequiredECSServices,
}