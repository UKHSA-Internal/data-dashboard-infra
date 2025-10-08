const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const BrokenLinkCheckerReport = require('BrokenLinkCheckerReport');
const SyntheticsLink = require('SyntheticsLink');
const syntheticsLogHelper = require('SyntheticsLogHelper');
const syntheticsConfiguration = synthetics.getConfiguration();


function extractUrlsFromSitemap(xml) {
    const urlRegex = /<loc>(.*?)<\/loc>/g;
    const urls = [];
    let match;

    while ((match = urlRegex.exec(xml)) !== null) {
        urls.push(match[1].trim());
    }
    return urls;
}

async function parseSitemap(url) {
    const response = await fetch(url);
    const xmlString = await response.text();
    return extractUrlsFromSitemap(xmlString)
}

async function fetchAndParseSitemap(url) {
    try {
        return await parseSitemap(url)
    } catch (error) {
        log.error("Error fetching or parsing XML:", error);
    }
}

// maximum number of links that would be followed
const limit = null;

// Captures destination page screenshot after loading a link successfully.
const captureDestinationPageScreenshotOnSuccess = false;

// Captures destination page screenshot for broken links only. Note that links which do not return response have no destination screenshots.
const captureDestinationPageScreenshotOnFailure = true;

// Close and Re-launch browser after checking these many links. This clears up /tmp disk storage occupied by chromium and launches a new browser for next set of links.
// Increase or decrease based on complexity of your website.
const numOfLinksToReLaunchBrowser = 1000;

// Take synthetics screenshot
const takeScreenshot = async function (fileName, suffix) {
    try {
        return await synthetics.takeScreenshot(fileName, suffix);
    } catch (e) {
        synthetics.addExecutionError('Unable to capture screenshot.', e);
    }
}

// Get the fileName for the screenshot based on the URI
const getFileName = function (url, defaultName = 'loaded') {
    if (!url) return defaultName;

    const uri = new URL(url);
    const pathname = uri.pathname.replace(/\/$/, ''); //remove trailing '/'
    const fileName = !!pathname ? pathname.split('/').pop() : 'index';

    // Remove characters which can't be used in S3
    return fileName.replace(/[^a-zA-Z0-9-_.!*'()]+/g, '');
}

// Broken link checker blueprint just uses one page to test availability of several urls
// Reset the page in-between to force a network event in case of a single page app
const resetPage = async function (page) {
    try {
        await page.goto('about:blank', {waitUntil: ['load'], timeout: 30000});
    } catch (e) {
        synthetics.addExecutionError('Unable to open a blank page ', e);
    }
}

const webCrawlerBlueprint = async function () {
    const urls = await fetchAndParseSitemap(process.env.SITEMAP_URL);
    const exploredUrls = urls.slice();
    let synLinks = [];
    let count = 0;

    let canaryError = null;
    let brokenLinkError = null;

    let brokenLinkCheckerReport = new BrokenLinkCheckerReport();

    syntheticsConfiguration.setConfig({
        harFile: false,
        includeRequestHeaders: true,
        includeResponseHeaders: true,
        restrictedHeaders: [], // Value of these headers will be redacted from logs and reports
        restrictedUrlParameters: [] // Values of these url parameters will be redacted from logs and reports
    });

    // Synthetics Puppeteer page instance
    let page = await synthetics.getPage();

    exploredUrls.forEach(url => {
        synLinks.push(new SyntheticsLink(url));
    });

    while (synLinks.length > 0) {
        let link = synLinks.shift();
        let nav_url = link.getUrl();
        let sanitized_url = syntheticsLogHelper.getSanitizedUrl(nav_url);
        link.withUrl(sanitized_url);
        let fileName = getFileName(sanitized_url);
        let response = null;

        count++;

        log.info("Current count: " + count + " Checking URL: " + sanitized_url);

        if (count % numOfLinksToReLaunchBrowser === 0 && count !== limit) {
            log.info("Closing current browser and launching new");

            // Close browser and stops HAR logging.
            await synthetics.close();

            // Launches a new browser and start HAR logging.
            await synthetics.launch();

            page = await synthetics.getPage();
        } else if (count !== 1) {
            await resetPage(page);
        }

        try {
            /* You can customize the wait condition here. For instance, using 'networkidle2' may be less restrictive.
                networkidle0: Navigation is successful when the page has had no network requests for half a second. This might never happen if page is constantly loading multiple resources.
                networkidle2: Navigation is successful when the page has no more then 2 network requests for half a second.
                domcontentloaded: It's fired as soon as the page DOM has been loaded, without waiting for resources to finish loading. If needed add explicit wait with await new Promise(r => setTimeout(r, milliseconds))
            */

            response = await page.goto(nav_url, {waitUntil: ['load'], timeout: 30000});
            if (!response) {
                brokenLinkError = "Failed to receive network response for url: " + sanitized_url;
                log.error(brokenLinkError);
                link = link.withFailureReason('Received null or undefined response.');
            }
        } catch (e) {
            brokenLinkError = "Failed to load url: " + sanitized_url + ". " + e;
            log.error(brokenLinkError);
            link = link.withFailureReason(e.toString());
        }

        if (response && response.status() && response.status() < 400) {
            link = link.withStatusCode(response.status()).withStatusText(response.statusText());
            if (captureDestinationPageScreenshotOnSuccess) {
                let screenshotResult = await takeScreenshot(fileName, 'succeeded');
                link.addScreenshotResult(screenshotResult);
            }
        } else if (response) { // Received 400s or 500s
            const statusString = "Status code: " + response.status() + " " + response.statusText();
            brokenLinkError = "Failed to load url: " + sanitized_url + ". " + statusString;
            log.info(brokenLinkError);

            link = link.withStatusCode(response.status()).withStatusText(response.statusText()).withFailureReason(statusString);

            if (captureDestinationPageScreenshotOnFailure) {
                let screenshotResult = await takeScreenshot(fileName, 'failed');
                link.addScreenshotResult(screenshotResult);
            }
        }

        try {
            // Adds this link to broken link checker report. Link with status code >= 400 is considered broken.
            // Use addLink(link, isBrokenLink) to override this default behavior.
            brokenLinkCheckerReport.addLink(link);
        } catch (e) {
            synthetics.addExecutionError('Unable to add link to broken link checker report.', e);
        }
    }

    try {
        synthetics.addReport(brokenLinkCheckerReport);
    } catch (e) {
        synthetics.addExecutionError('Unable to add broken link checker report.', e);
    }

    log.info("Total links checked: " + brokenLinkCheckerReport.getTotalLinksChecked());

    // Fail canary if 1 or more broken links found.
    if (brokenLinkCheckerReport.getTotalBrokenLinks() > 0) {
        brokenLinkError = brokenLinkCheckerReport.getTotalBrokenLinks() + " broken link(s) detected. " + brokenLinkError;
        log.error(brokenLinkError);
        canaryError = canaryError ? (brokenLinkError + " " + canaryError) : brokenLinkError;
    }

    if (canaryError) {
        throw new Error(canaryError);
    }
};

exports.handler = async () => {
    return await webCrawlerBlueprint();
};
