const fs = require('fs');
const { execSync } = require('child_process');

// Helper function to run a bash script
function runScript(scriptPath, envVars = {}) {
    try {
        console.log(`Running script: ${scriptPath}`);
        execSync(`bash ${scriptPath}`, { stdio: 'inherit', env: { ...process.env, ...envVars } });
        return true;
    } catch (error) {
        console.error(`Script ${scriptPath} failed with error:`, error.message);
        return false;
    }
}

// Step 1: Run Pod Verification Script
if (runScript('./scripts/pod_verification.sh')) {
    console.log('Pod verification succeeded. Proceeding to sanity test.');

    // Step 2: Run Sanity Test Script only if Pod Verification was successful
    if (runScript('./scripts/sanity_test.sh')) {
        console.log('Sanity test passed.');
        runScript('./scripts/notification.sh', { WORKFLOW_STATUS: 'success' });
    } else {
        console.error('Sanity test failed.');

        // Step 3: Run Revert Script if Sanity Test fails
        if (runScript('./scripts/revert_script.sh')) {
            console.log('Reverted values.yaml due to sanity test failure.');
        }

        // Notify failure
        runScript('./scripts/notification.sh', { WORKFLOW_STATUS: 'failure' });
    }
} else {
    console.error('Pod verification failed. Exiting workflow.');

    // Notify failure immediately if Pod Verification fails
    runScript('./scripts/notification.sh', { WORKFLOW_STATUS: 'failure' });
}
