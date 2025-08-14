const lowStockRepository = require("lowStockRepository");

exports.fetchLowStockAlerts = async (companyId) => {
  return await lowStockRepository.getLowStockAlerts(companyId);
};
