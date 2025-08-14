const lowStockService = require("lowStockService");

exports.getLowStockAlerts = async (req, res) => {
  const { company_id } = req.params;

  try {
    const alerts = await lowStockService.fetchLowStockAlerts(company_id);

    res.json({
      alerts: alerts.map(row => ({
        product_id: row.product_id,
        product_name: row.product_name,
        sku: row.sku,
        warehouse_id: row.warehouse_id,
        warehouse_name: row.warehouse_name,
        current_stock: row.current_stock,
        threshold: row.threshold,
        days_until_stockout: row.days_until_stockout,
        supplier: {
          id: row.supplier_id,
          name: row.supplier_name,
          contact_email: row.contact_email
        }
      })),
      total_alerts: alerts.length
    });

  } catch (err) {
    console.error("Error fetching low-stock alerts:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};
