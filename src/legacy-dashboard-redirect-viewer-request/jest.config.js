export default {
  reporters: ["default", "jest-junit"],
  coverageProvider: "v8",
  coverageReporters: ["json-summary", "text"],
  collectCoverageFrom: ["index.js"],
};
