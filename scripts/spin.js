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

// Function to handle Pod Verification result
function handlePodVerification() {
    if (fs.existsSync('/tmp/pod_verification_result.json')) {
        const result = JSON.parse(fs.readFileSync('/tmp/pod_verification_result.json'));
        if (result.status === 'success') {
            console.log('Pod verification passed. Proceeding to sanity test...');
            runScript('./scripts/sanity_test.sh');
        } else {
            console.error('Pod verification failed. Stopping workflow.');
            process.exit(1);  // Stop the workflow if verification failed
        }
    } else {
        console.error('Pod verification result file not found.');
        process.exit(1);
    }
}

// Function to handle Sanity Test result
function handleSanityTest() {
    if (fs.existsSync('/tmp/sanity_test_result.json')) {
        const result = JSON.parse(fs.readFileSync('/tmp/sanity_test_result.json'));
        if (result.status === 'success') {
            console.log('Sanity test passed. No need to revert.');
        } else {
            console.error('Sanity test failed. Proceeding to revert...');
            runScript('./scripts/revert_script.sh');
        }
    } else {
        console.error('Sanity test result file not found.');
        process.exit(1);
    }
}

// Determine which result we're handling
if (fs.existsSync('/tmp/pod_verification_result.json')) {
    handlePodVerification();  // Handle pod verification result
} else if (fs.existsSync('/tmp/sanity_test_result.json')) {
    handleSanityTest();  // Handle sanity test result
} else {
    console.error('No result files found. Unable to proceed.');
    process.exit(1);
}
