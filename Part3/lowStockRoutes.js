const express = require("express");
const router = express.Router();
const lowStockController = require("lowStockController");

router.get("/api/companies/:company_id/alerts/low-stock", lowStockController.getLowStockAlerts);

module.exports = router;
