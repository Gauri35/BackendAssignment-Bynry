const db = require("../db");

/*
ASSUMPTIONS - Sales table exists with the following columns:

CREATE TABLE sales (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
);

*/

exports.getLowStockAlerts = async (companyId) => {
  return db.any(`
    WITH recent_sales AS (
      SELECT 
        product_id,
        warehouse_id,
        SUM(quantity) / 30.0 AS avg_daily_sales
      FROM sales
      WHERE sale_date >= NOW() - INTERVAL '30 days'
      GROUP BY product_id, warehouse_id
    )
    SELECT
      p.id AS product_id,
      p.name AS product_name,
      p.sku,
      w.id AS warehouse_id,
      w.name AS warehouse_name,
      i.quantity AS current_stock,
      p.low_stock_threshold AS threshold,
      CASE 
        WHEN rs.avg_daily_sales > 0 
        THEN FLOOR(i.quantity / rs.avg_daily_sales)
        ELSE NULL
      END AS days_until_stockout,
      s.id AS supplier_id,
      s.name AS supplier_name,
      s.contact_email
    FROM products p
    JOIN inventory i 
      ON p.id = i.product_id
    JOIN warehouses w 
      ON i.warehouse_id = w.id
    JOIN recent_sales rs 
      ON p.id = rs.product_id AND w.id = rs.warehouse_id
    LEFT JOIN supplier_products sp 
      ON p.id = sp.product_id
    LEFT JOIN suppliers s 
      ON sp.supplier_id = s.id
    WHERE w.company_id = $1
      AND i.quantity < p.low_stock_threshold
  `, [companyId]);
};
