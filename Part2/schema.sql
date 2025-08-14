CREATE TABLE companies (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE warehouses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    location TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_warehouse_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    CONSTRAINT uq_company_warehouse UNIQUE (company_id, name)
);

CREATE TABLE suppliers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    phone_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(12,2) NOT NULL,
    is_bundle BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    low_stock_threshold INT NOT NULL DEFAULT 10
    CONSTRAINT fk_product_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);


CREATE TABLE product_bundles (
    bundle_product_id BIGINT NOT NULL,
    component_product_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (bundle_product_id, component_product_id),
    CONSTRAINT fk_bundle_product FOREIGN KEY (bundle_product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_component_product FOREIGN KEY (component_product_id) REFERENCES products(id) ON DELETE CASCADE
);


CREATE TABLE supplier_products (
    supplier_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    PRIMARY KEY (supplier_id, product_id),
    CONSTRAINT fk_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE,
    CONSTRAINT fk_supplier_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);


CREATE TABLE inventory (
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id, warehouse_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
);


CREATE TABLE inventory_history (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    change_quantity INT NOT NULL,
    reason VARCHAR(255),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    CONSTRAINT fk_history_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
);

-- Look up products quickly by SKU within a company
CREATE UNIQUE INDEX idx_products_company_sku ON products(company_id, sku);

-- Query inventory fast by warehouse or product
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);

-- Look up history changes quickly by product
CREATE INDEX idx_history_product_date ON inventory_history(product_id, changed_at DESC);

-- Supplier product lookup
CREATE INDEX idx_supplier_products_supplier ON supplier_products(supplier_id);

-- Trigger to track inventory changes
CREATE TRIGGER trg_inventory_change
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.quantity <> OLD.quantity THEN
        INSERT INTO inventory_history (
            product_id, warehouse_id, change_quantity, reason, changed_by
        ) VALUES (
            NEW.product_id, NEW.warehouse_id, NEW.quantity - OLD.quantity,
            'SYSTEM UPDATE', CURRENT_USER()
        );
    END IF;
END;


